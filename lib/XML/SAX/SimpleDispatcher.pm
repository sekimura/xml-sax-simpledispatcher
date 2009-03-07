package XML::SAX::SimpleDispatcher;

use base qw(XML::SAX::Base);
use 5.008001;

use List::Util qw(first);
use Data::Dumper;

use constant CALLBACK => 0;
use constant EXPR     => 1;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %param = @_;
    my $proc = $param{process};
    for my $key (keys %$proc) {
        $self->{__proc}{$key} = $proc->{$key};
        $self->{__cb}{$key} = $proc->{$key}->[CALLBACK];
    }
    return $self;
}

sub start_document {
    my $self = shift;
    $self->{__elements} = [];
}

sub start_element {
    my $self = shift;
    my ($data) = @_;

    my $elements = $self->{__elements};
    my $parent_path = '/' . join ('/', @$elements);

    my $name = $data->{Name};
    my %attrs =
      map { $data->{Attributes}{$_}{Name} => $data->{Attributes}{$_}{Value} }
      keys %{ $data->{Attributes} };

    if ( $self->{__proc}{$parent_path} and ! $self->{__stash}{$parent_path}) {
        $self->{__stash}{$parent_path} =
          { map { $_ => undef } @{ $self->{__proc}{$parent_path}->[EXPR] } };
    }

    push @$elements, $name;
}

sub characters {
    my $self = shift;
    my ($data) = @_;

    my $elements = $self->{__elements};
    my $current  = $elements->[-1] or return;
    my $parent_path = '/' . join ('/', @$elements[0..$#$elements-1]);
    my $chars = $data->{Data};
    if ($self->{__stash}{$parent_path}) {
        if (my $val = $self->{__stash}{$parent_path}{$current}) {
            if (ref $val eq 'ARRAY') {
                push @{$self->{__stash}{$parent_path}{$current}}, $chars;
            }
            else {
                $self->{__stash}{$parent_path}{$current} = [$val, $chars];
            }
        }
        else {
            $self->{__stash}{$parent_path}{$current} = $chars;
        }
    }
}

sub end_element {
    my $self = shift;
    my ($data) = @_;

    my $elements = $self->{__elements};
    my $current  = $elements->[-1] or return;
    my $path = '/' . join ('/', @$elements);

    if ($self->{__stash}{$path}) {
        my $stash = delete $self->{__stash}{$path};
        my @ret = map {$stash->{$_}} @{$self->{__proc}{$path}->[EXPR]};
        $self->{__cb}{$path}->(@ret);
    }

    pop @$elements;
}

1;
