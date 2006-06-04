package PPI::Token;

=pod

=head1 NAME

PPI::Token - A single token of Perl source code

=head1 INHERITANCE

  PPI::Token
  isa PPI::Element

=head1 DESCRIPTION

C<PPI::Token> is the abstract base class for all Tokens. In PPI terms, a "Token" is
a L<PPI::Element> that directly represents bytes of source code.

=head1 METHODS

=cut

use strict;
use base 'PPI::Element';
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.114';
}

# We don't load the abstracts, they are loaded
# as part of the 'use base' statements.

# Load the token classes
use PPI::Token::Whitespace            ();
use PPI::Token::Comment               ();
use PPI::Token::Pod                   ();
use PPI::Token::Number                ();
use PPI::Token::Word                  ();
use PPI::Token::DashedWord            ();
use PPI::Token::Symbol                ();
use PPI::Token::ArrayIndex            ();
use PPI::Token::Magic                 ();
use PPI::Token::Quote::Single         ();
use PPI::Token::Quote::Double         ();
use PPI::Token::Quote::Literal        ();
use PPI::Token::Quote::Interpolate    ();
use PPI::Token::QuoteLike::Backtick   ();
use PPI::Token::QuoteLike::Command    ();
use PPI::Token::QuoteLike::Regexp     ();
use PPI::Token::QuoteLike::Words      ();
use PPI::Token::QuoteLike::Readline   ();
use PPI::Token::Regexp::Match         ();
use PPI::Token::Regexp::Substitute    ();
use PPI::Token::Regexp::Transliterate ();
use PPI::Token::Operator              ();
use PPI::Token::Cast                  ();
use PPI::Token::Structure             ();
use PPI::Token::Label                 ();
use PPI::Token::HereDoc               ();
use PPI::Token::Separator             ();
use PPI::Token::Data                  ();
use PPI::Token::End                   ();
use PPI::Token::Prototype             ();
use PPI::Token::Attribute             ();
use PPI::Token::Unknown               ();





#####################################################################
# Constructor and Related

sub new {
	if ( @_ == 2 ) {
		# PPI::Token->new( $content );
		my $class = $_[0] eq __PACKAGE__ ? 'PPI::Token::Whitespace' : shift;
		return bless {
			content => (defined $_[0] ? "$_[0]" : '')
			}, $class;
	} elsif ( @_ == 3 ) {
		# PPI::Token->new( $class, $content );
		my $class = substr( $_[0], 0, 12 ) eq 'PPI::Token::' ? $_[1] : "PPI::Token::$_[1]";
		return bless {
			content => (defined $_[2] ? "$_[2]" : '')
			},  $class;
	}

	# Invalid argument count
	undef;
}

sub set_class {
	my $self  = shift; @_ or return undef;
	my $class = substr( $_[0], 0, 12 ) eq 'PPI::Token::' ? shift : 'PPI::Token::' . shift;

	# Find out if the current and new classes are complex
	my $old_quote = (ref($self) =~ /\b(?:Quote|Regex)\b/o) ? 1 : 0;
	my $new_quote = ($class =~ /\b(?:Quote|Regex)\b/o)     ? 1 : 0;

	# No matter what happens, we will have to rebless
	bless $self, $class;

	# If we are changing to or from a Quote style token, we
	# can't just rebless and need to do some extra thing
	# Otherwise, we have done enough
	return 1 if ($old_quote - $new_quote) == 0;

	# Make a new token from the old content, and overwrite the current
	# token's attributes with the new token's attributes.
	my $token = $class->new( $self->{content} ) or return undef;
	delete $self->{$_} foreach keys %$self;
	$self->{$_} = $token->{$_} foreach keys %$token;

	1;
}





#####################################################################
# PPI::Token Methods

=pod

=head2 set_content $string

The C<set_content> method allows to set/change the string that the
C<PPI::Token> object represents.

Returns the string you set the Token to

=cut

sub set_content {
	$_[0]->{content} = $_[1];
}

=pod

=head2 add_content $string

The C<add_content> method allows you to add additional bytes of code
to the end of the Token.

Returns the new full string after the bytes have been added.

=cut

sub add_content { $_[0]->{content} .= $_[1] }

=pod

=head2 length

The C<length> method returns the length of the string in a Token.

=cut

sub length { &CORE::length($_[0]->{content}) }





#####################################################################
# Overloaded PPI::Element methods

sub content {
	$_[0]->{content};
}

# You can insert either a statement, or a non-significant token.
sub insert_before {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element')  or return undef;
	if ( $Element->isa('PPI::Structure') ) {
		return $self->__insert_before($Element);
	} elsif ( $Element->isa('PPI::Token') ) {
		return $self->__insert_before($Element);
	}
	'';
}

# As above, you can insert a statement, or a non-significant token
sub insert_after {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;
	if ( $Element->isa('PPI::Structure') ) {
		return $self->__insert_after($Element);
	} elsif ( $Element->isa('PPI::Token') ) {
		return $self->__insert_after($Element);
	}
	'';
}





#####################################################################
# Tokenizer Methods

sub __TOKENIZER__on_line_start { 1 }
sub __TOKENIZER__on_line_end   { 1 }
sub __TOKENIZER__on_char       { 'Unknown' }





#####################################################################
# Lexer Methods

sub __LEXER__opens {
	ref($_[0]) eq 'PPI::Token::Structure'
	and
	$_[0]->{content} =~ /(?:\(|\[|\{)/
}

sub __LEXER__closes {
	ref($_[0]) eq 'PPI::Token::Structure'
	and
	$_[0]->{content} =~ /(?:\)|\]|\})/
}

1;