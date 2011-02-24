package Mason::Plugin::RouterSimple::t::Basic;
BEGIN {
  $Mason::Plugin::RouterSimple::t::Basic::VERSION = '0.01';
}
use Test::Class::Most parent => 'Mason::Test::Class';

__PACKAGE__->default_plugins( [ '@Default', 'RouterSimple' ] );

sub test_ok : Test(10) {
    my $self = shift;
    $self->add_comp(
        path => '/foo.m',
        src  => '
%% route "bar";
%% route "wiki/:page", { action => "wiki" };
%% route "download/*.*", { action => "download" };
%% route "blog/{year:[0-9]+}/{month:[0-9]{2}}";

<%args>
$.page => (default => "standard")
</%args>

month = <% $.month || "undef" %>
page = <% $.page || "standard" %>
splat = <% $.splat ? split(",", $.splat) : "undef" %>

% $m->result->data->{args} = $.args;
',
    );

    my $try = sub {
        my ( $path, $expect ) = @_;

        my $result;
        if ($expect) {
            my $month = $expect->{month} || "undef";
            my $page  = $expect->{page}  || "standard";
            my $splat = $expect->{splat} ? split( ',', $expect->{splat} ) : "undef";
            $self->test_comp(
                path        => $path,
                expect      => "month = $month\npage = $page\nsplat = $splat",
                expect_data => { args => { %$expect, router_result => $expect } },
            );
        }
        else {
            $self->test_comp( path => $path, expect_error => qr/could not find component/ );
        }
    };

    $try->( '/foo/bar',               {} );
    $try->( '/foo/wiki/abc',          { action => 'wiki', page => 'abc' } );
    $try->( '/foo/download/tune.mp3', { action => 'download', splat => [ 'tune', 'mp3' ] } );
    $try->( '/foo/blog/2010/02', { year => '2010', month => '02' } );
    $try->( '/foo/baz',          undef );
    $try->( '/foo/blog/201O/02', undef );
}

1;
