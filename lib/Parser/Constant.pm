#########################################################################
#
#  Implements named constants (e, pi, etc.)
#
package Parser::Constant;
use strict;
our @ISA = qw(Parser::Item);

$Parser::class->{Constant} = 'Parser::Constant';

#
#  If a constant is marked with isConstant, then it will
#  be combined with other constants automatically as formulas
#  are built, so only mark it if you want that to happen.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift;
  my ($name,$ref) = @_;
  my $const = $equation->{context}{constants}{$name};
  my ($value,$type) = Value::getValueType($equation,$const->{value});
  my $c = bless {
    name => $name, type => $type, def => $const,
    ref => $ref, equation => $equation
  }, $class;
  $c->{isConstant} = 1 if $const->{isConstant};
  return $c;
}

#
#  Return the value of the constant
#    (for formulas, do the same substitutions the are in
#     effect for the main equation).
#
sub eval {
  my $self = shift; my $context = $self->context;
  my $data = $self->{def}{value};
  if (Value::isFormula($data)) {
    $data->{values} = $self->{equation}{values};
    my $value = $data->{tree}->eval;
    $data->{values} = {};
    return $value->inContext($self->context);
  } elsif (ref($data) eq 'ARRAY') {
    foreach my $x (@{$data}) {$x->inContext($context)}
    return @{$data};
  } else {
    $data = $data->inContext($context) if Value::isValue($data);
    return $data;
  }
}

#
#  Use constant to tell if it can be in a union
#
sub canBeInUnion {
  my $self = shift;
  Value::isValue($self->{def}{value}) && $self->{def}{value}->canBeInUnion;
}

#
#  Return the constant's name
#
sub string {
  my $self = shift;
  return $self->{def}{string} if defined($self->{def}{string});
  return $self->{name}
}

sub TeX {
  my $self = shift; my $name = $self->{name};
  return $self->{def}{TeX} if defined($self->{def}{TeX});
  $name = $1.'_{'.$2.'}' if ($name =~ m/^(\D+)(\d+)$/);
  return $name;
}

sub perl {
  my $self = shift; my $parens = shift;
  my $data = $self->{def}{value};
  return $self->{def}{perl} if defined($self->{def}{perl});
  if (Value::isFormula($data)) {
    $data->{values} = $self->{equation}{values};
    my $value = $data->{tree}->perl;
    $data->{values} = {};
    $value = '('.$value.')' if $parens;
    return $value;
  }
  $data = Value::makeValue($data,context=>$self->context);
  return $data->perl(@_) if Value::isValue($data);
  return '$'.$self->{name};
}

#########################################################################

1;
