package Nagios::Plugin::BSD::Thermal;

# ABSTRACT: Nagios plugin to check temperature via sysctl hw.acpi.thermal

use strict;
use warnings;

use base 'Nagios::Plugin';

use Nagios::Plugin;
#use Nagios::Plugin::DieNicely;
use BSD::Sysctl;
use Data::Dump;

sub new {
	my ($class) = @_;

	my $self = $class->SUPER::new(
		usage => "usage: %s [-w <warn>] [-c <crit>] [-z <zone>]",
	);

	$self->add_arg(%$_) for (
		{
			spec => "warning|w=f",
			help => "-w, --warning=REAL\n  Temperature to result in WARNING status. Defaults to passive cooling temperature.",
		},
		{
			spec => "critical|c=f",
			help => "-c, --critical=REAL\n  Temperature to result in CRITICAL status. Defaults to critical shutdown temperature.",
		},
		{
			spec => "zone|z=i",
			help => "-z, --zone=INT\n  Thermal zone to measure. Defaults to 0 (tz0).",
		}
	);

	return $self;
}

sub run {
	my ($self) = @_;

	$self->getopts;

	my $zone     = $self->opts->zone     || 0;

	my $temp = BSD::Sysctl::sysctl("hw.acpi.thermal.tz${zone}.temperature")/10-273.2;
dd $temp;
	my $warning  = $self->opts->warning  || BSD::Sysctl::sysctl("hw.acpi.thermal.tz${zone}._PSV")/10-273.2;
	my $critical = $self->opts->critical || BSD::Sysctl::sysctl("hw.acpi.thermal.tz${zone}._CRT")/10-273.2;

	$self->set_thresholds(warning => $warning, critical => $critical);
	$self->add_message($self->check_threshold($temp), sprintf "tz${zone} temp is %.1f C",  ${temp});
	$self->add_perfdata(
		label     => 'temp',
		value     => $temp,
		uom       => 'C',
		threshold => $self->threshold
	);
	$self->nagios_exit($self->check_messages(join => ", "));
}

1;
