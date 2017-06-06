# Convenience package to read passwords etc. needed to connect to the
# Bacula (or Bareos) database.

package Bacula::DatabaseConfig;

use Getopt::Long;
use DBI;

use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(HELP_MESSAGE connect disconnect);

sub HELP_MESSAGE {
    return <<_END_;
Available options to configure database access:
  --database-config FILE  database connection settings
  --database-name DBNAME
  --database-dsn DSN
  --database-user USER
  --database-password PASSWORD
_END_
}

# This is a class variable so that @ARGV has effect for all created
# objects.
my $override = {};

sub new {
    my ($class, %params) = @_;

    my $self = \%params;
    bless $self, $class;

    my $impl = -d '/etc/bareos' ? 'bareos' : 'bacula';

    $self->{default_config} = {
        'database-name' => $impl,
        'database-host' => 'localhost',
        'database-user' => $impl,
        'database-password' => '',
        'database-dsn' => undef,
    };

    $self->{config_files} ||= [
        "$ENV{HOME}/.bacula-database.cf",
        "/etc/bareos/bacula-database.cf",
        "/etc/bacula/bacula-database.cf",
        ];
    $self->{config} = {};

    # We need to use OO interface to avoid configuring globally
    my $p = new Getopt::Long::Parser;
    $p->configure('pass_through');
    $p->getoptions(
        "database-config=s"   => sub { $self->{config_files} = [$_[1]] },
        "database-dsn=s"      => \$override->{'database-dsn'},
        "database-name=s"     => \$override->{'database-name'},
        "database-host=s"     => \$override->{'database-host'},
        "database-user=s"     => \$override->{'database-user'},
        "database-password=s" => \$override->{'database-password'},
    ) or main::usage();

    return $self;
}

sub keywords {
    keys %{$_[0]->{default_config}};
}

sub config {
    my ($self) = @_;
    return if scalar keys %{$self->{config}};

    my $file_config = $self->read_database_config(@{$self->{config_files}});
    for my $setting ($self->keywords) {
        # Since DSN may refer to overridden values, calculate its
        # default last.
        next if $setting eq 'database-dsn';
        $self->{config}->{$setting} =
            ($override->{$setting} ||
             $self->{$setting} ||
             $file_config->{$setting} ||
             $self->{default_config}->{$setting});
    }

    
    my $default_dsn = "dbi:Pg:dbname=$self->{config}->{'database-name'}";
    # use socket (default behaviour) if on localhost
    $default_dsn .= ";host=$self->{config}->{'database-host'}"
        if $self->{config}->{'database-host'} ne 'localhost';

    $self->{config}->{'database-dsn'} =
        $override->{'database-dsn'} ||
        $file_config->{'database-dsn'} ||
        $default_dsn;
}


sub dsn {
    my ($self) = @_;
    $self->config();
    return $self->{config}->{'database-dsn'};
}

sub user {
    my ($self) = @_;
    $self->config();
    return $self->{config}->{'database-user'};
}

sub password {
    my ($self) = @_;
    $self->config();
    return $self->{config}->{'database-password'};
}

sub connect {
    my ($self, %params) = @_;

    $params{AutoCommit} = 1 unless defined $params{AutoCommit};
    $self->{dbh} ||= DBI->connect($self->dsn, $self->user, $self->password,
                                  \%params)
        or die "DBI connect failed\n";
    return $self->{dbh};
}

sub disconnect {
    my ($self) = @_;

    die "disconnect but no known DB-handle"
        unless defined $self->{dbh};

    $self->{dbh}->disconnect;
    delete $self->{dbh};
}

# Read configuration file.  Syntax is "keyword value", and allowed
# keywords are fetched from keys in default_config.  Trailing
# comments are not allowed.

sub read_database_config {
    my ($self, @files) = @_;

    my $conf = {};
    my $keywords = join('|', $self->keywords);
    for my $filename (@files) {
        if (-e $filename) {
            open(my $fd, $filename) or die "open $filename: $!\n";
            while (<$fd>) {
                chomp;
                next if /^\s*#/;
                next if /^\s*$/;
                if (/^($keywords)\s+(.*)/) {
                    $conf->{$1} = $2;
                } else {
                    die "$filename:$.: Unknown keyword: $_\n";
                }
            }
            close($fd);
            last;
        }
    }
    return $conf;
}

1;
