use v6.c;
use File::Temp;
use JSON::Fast;

unit module ResourceExtractor:ver<0.0.3>;

sub get-resources-dir(
    Str :$module,
    Str :$version,
    Str :$api,
    Str :$auth,
    Distribution::Resources :%resources,
    --> IO
) is export
{
    my ($dist-id, $repo, $distribution);
    if %resources {
        $dist-id = %resources.dist-id;
        $repo = %resources.repo-name
            ?? CompUnit::RepositoryRegistry.repository-for-name(%resources.repo-name)
            !! CompUnit::RepositoryRegistry.repository-for-spec(%resources.repo);
        $distribution := $repo.distribution($dist-id);
    } elsif $module {
        my $spec = CompUnit::DependencySpecification.new(
            :short-name($module),
            :version-matcher($version // True),
            :auth-matcher($auth // True),
            :api-matcher($api // True),
        );
        my $comp-unit = $*REPO.resolve($spec);
        $distribution = $comp-unit.distribution;
        $repo         = $comp-unit.repo;
    } else {
        die 'either provide :short-name or %?RESOURCES as resources';
    }
    given $repo {
        when CompUnit::Repository::FileSystem {
            my $resources;

            # this is the /path/to/lib of perl6 -I/path/to/lib
            # so there are most likely no resources
            # so we check ../resources first
            $resources = $_.prefix.add('../resources');
            return $resources.resolve if $resources.e;

            # *shrug*
            $resources = $_.prefix.add('resources');
            return $resources if $resources.e;

            die "coudn't find resources in {{ $_.prefix }}";
        }
        when CompUnit::Repository::Installation {
            my $tempdir = tempdir().IO;
            my $meta    = $distribution.meta;
            $dist-id    //= $distribution.dist-id;
            for $meta<resources>.List -> $name {
                my $file       = $tempdir.add($name);
                my $parent-dir = $file.parent();
                my $resource   = $_.resource($dist-id, 'resources/' ~ $name);
                my $content    = $resource.slurp(:bin);
                $parent-dir.mkdir() unless $parent-dir.e;
                $file.spurt($content, :createonly);
            };
            return $tempdir;
        }
        default {
            die "dont know how to handle your repository {{ $_.^name  }}";
        }
    }
}

=begin pod

=head1 NAME

ResourceExtractor - blah blah blah

=head1 SYNOPSIS

  use ResourceExtractor;

=head1 DESCRIPTION

ResourceExtractor is ...

=head1 AUTHOR

Martin Barth <martin@senfdax.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Martin Barth

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
