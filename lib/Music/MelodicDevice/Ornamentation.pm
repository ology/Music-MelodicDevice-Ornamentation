package Music::MelodicDevice::Ornamentation;

# ABSTRACT: Chromatic and diatonic musical ornamentation

our $VERSION = '0.0100';

use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use List::SomeUtils qw(first_index);
use MIDI::Simple ();
use Music::Duration;
use Music::Scales qw(get_scale_notes is_scale);
use Music::Note;
use Moo;
use strictures 2;
use namespace::clean;

use constant TICKS => 96;

=head1 SYNOPSIS

  use Music::MelodicDevice::Ornamentation;

  # Chromatic
  my $md = Music::MelodicDevice::Ornamentation->new;
  my $spec = $md->grace_note('qn', 'D5', 1); # [[xn D#5], [d90 D5]]
  $spec = $md->turn('qn', 'D5', 1);          # [[sn D#5], [sn D5], [sn C#5], [sn D5]]
  $spec = $md->trill('qn', 'D5', 2, 1);      # [[sn D#5], [sn D5], [sn D#5], [sn D5]]
  $spec = $md->mordent('qn', 'D5', 1);       # [[yn D5], [yn D#5], [den D5]]

  # Diatonic
  $md = Music::MelodicDevice::Ornamentation->new(scale_name => 'major');
  $spec = $md->grace_note('qn', 'D5', 1); # [[xn E5], [d90 D5]]
  $spec = $md->turn('qn', 'D5', 1);       # [[sn E5], [sn D5], [sn C5], [sn D5]]
  $spec = $md->trill('qn', 'D5', 2, 1);   # [[sn E5], [sn D5], [sn E5], [sn D5]]
  $spec = $md->mordent('qn', 'D5', 1);    # [[yn D5], [yn E5], [den D5]]

=head1 DESCRIPTION

C<Music::MelodicDevice::Ornamentation> provides chromatic and diatonic
musical ornamentation methods.

The duration part of the returned note specifications is in
L<MIDI::Simple> C<d###> style, even though the SYNOPSIS shows them as
L<MIDI::Simple> abbreviations.  This is for conceptual reasons only.

=head1 ATTRIBUTES

=head2 scale_note

Default: C<C>

=cut

has scale_note => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/ },
    default => sub { 'C' },
);

=head2 scale_name

Default: C<chromatic>

For the chromatic scale, enharmonic notes are listed as sharps.  For a
scale with flats, a diatonic B<scale_name> must be used with a flat
B<scale_note>.

Please see L<Music::Scales/SCALES> for a list of valid scale names.

=cut

has scale_name => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid scale name" unless is_scale($_[0]) },
    default => sub { 'chromatic' },
);

has _scale => (
    is        => 'lazy',
    init_args => undef,
);

sub _build__scale {
    my ($self) = @_;

    my @scale = get_scale_notes($self->scale_note, $self->scale_name);
    print 'Scale: ', ddc(\@scale) if $self->verbose;

    my @with_octaves = map { my $o = $_; map { $_ . $o } @scale } 0 .. 10;
    print 'With octaves: ', ddc(\@with_octaves) if $self->verbose;

    return \@with_octaves;
}

=head2 verbose

Default: C<0>

=cut

has verbose => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

=head1 METHODS

=head2 new

  $x = Music::MelodicDevice::Ornamentation->new(
    scale_note => $scale_note,
    scale_name => $scale_name,
    verbose => $verbose,
  );

Create a new C<Music::MelodicDevice::Ornamentation> object.

=cut

=head2 grace_note

  $spec = $md->grace_note($duration, $pitch, $offset);

"Appoggiatura" means emphasis on the grace note.  "Acciaccatura" means
emphasis on the main note.  This module doesn't accent notes.  You'll
have to do that bit.

=cut

sub grace_note {
    my ($self, $duration, $pitch, $offset) = @_;

    my $grace_note;
    if ($self->scale_name eq 'chromatic') {
        my $note = Music::Note->new($pitch, 'ISO')->format('midinum') + $offset;
        $grace_note = Music::Note->new($note, 'midinum')->format('ISO');
    }
    else {
        my $i = first_index { $_ eq $pitch } @{ $self->_scale };
        $grace_note = $self->_scale->[ $i + $offset ];
    }
    print "Grace note: $grace_note\n" if $self->verbose;

    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $y = $MIDI::Simple::Length{xn} * TICKS; # Sixtyfourth note
    my $z = sprintf '%0.f', ($x - $y);
    print "Durations: $x, $y, $z\n" if $self->verbose;

    return [ ['d' . $y, $grace_note], ['d' . $z, $pitch] ];
}

=head2 turn

  $spec = $md->turn($duration, $pitch, $direction);

The note Above, the Principle note (the B<pitch>), the note Below, the
Principle note again.

The default B<direction> is C<1>, but if given as C<-1>, the turn is
"inverted" and goes: Below, Principle, Above, Principle.

=cut

sub turn {
    my ($self, $duration, $pitch, $direction) = @_;

    $direction ||= 1;

    my ($above, $below);

    if ($self->scale_name eq 'chromatic') {
        $above = Music::Note->new($pitch, 'ISO')->format('midinum') + 1;
        $above = Music::Note->new($above, 'midinum')->format('ISO');
        $below = Music::Note->new($pitch, 'ISO')->format('midinum') - 1;
        $below = Music::Note->new($below, 'midinum')->format('ISO');
    }
    else {
        my $i = first_index { $_ eq $pitch } @{ $self->_scale };
        $above = $self->_scale->[ $i + 1 ];
        $below = $self->_scale->[ $i - 1 ];
    }
    print "Above/Below: $above / $below\n" if $self->verbose;

    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $z = sprintf '%0.f', ($x / 4);
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @turn;

    if ($direction == 1) {
        push @turn, [$z, $above], [$z, $pitch], [$z, $below], [$z, $pitch];
    }
    elsif ($direction == -1) {
        push @turn, [$z, $below], [$z, $pitch], [$z, $above], [$z, $pitch];
    }
    else {
        croak "Unknown turn direction: $direction";
    }
    print 'Turn: ', ddc(\@turn) if $self->verbose;

    return \@turn;
}

=head2 trill

  $spec = $md->trill($duration, $pitch, $number, $offset);

A trill is a B<number> of pairs of notes spread over a given
B<duration>.  The first of the pair being the given B<pitch> and the
second one given by the B<offset>.

=cut

sub trill {
    my ($self, $duration, $pitch, $number, $offset) = @_;

    $number ||= 4;
    $offset ||= 1;

    my $alt;

    if ($self->scale_name eq 'chromatic') {
        $alt = Music::Note->new($pitch, 'ISO')->format('midinum') + $offset;
        $alt = Music::Note->new($alt, 'midinum')->format('ISO');
    }
    else {
        my $i = first_index { $_ eq $pitch } @{ $self->_scale };
        $alt = $self->_scale->[ $i + $offset ];
    }
    print "Alternate note: $alt\n" if $self->verbose;

    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $z = sprintf '%0.f', ($x / $number / 2);
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @trill;

    push @trill, [$z, $pitch], [$z, $alt] for 1 .. $number;

    return \@trill;
}

=head2 mordent

  $spec = $md->mordent($duration, $pitch, $number, $offset);

* CURRENTLY UNIMPLEMENTED *

"A rapid alternation between an indicated note [the B<pitch>], the
note above or below, and the indicated note again."

=cut

sub mordent {
    my ($self, $duration, $pitch, $offset) = @_;
    my @mordent;
    return \@mordent;
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> program in this distribution

L<Carp>

L<Data::Dumper::Compact>

L<List::SomeUtils>

L<MIDI::Simple>

L<Moo>

L<Music::Duration>

L<Music::Note>

L<Music::Scales>

L<https://en.wikipedia.org/wiki/Ornament_(music)>

=cut
