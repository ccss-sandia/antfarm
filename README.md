antfarm(1) -- passive network mapping tool
==========================================

## SYNOPSIS

`antfarm [ <global options> ] command|plugin [ <command/plugin options> ]`

`antfarm -h, --help`

## DESCRIPTION

ANTFARM (Advanced Network Toolkit For Assessments and Remote Mapping) is a
passive network mapping application that utilizes output from existing network
examination tools to populate its OSI-modeled database. This data can then be
used to form a ‘picture’ of the network being analyzed.

ANTFARM can also be described as a data fusion tool that does not directly
interact with the network. The analyst can use a variety of passive or active
data gathering techniques, the outputs of which are loaded into ANTFARM and
incorporated into the network map. Data gathering can be limited to completely
passive techniques when minimizing the risk of disrupting the operational
network is a concern.

## DISCLAIMER

While the ANTFARM tool itself is completely passive (it does not have any
built-in means of gathering data directly from devices or networks), network
admin tools that users of ANTFARM may choose to gather data with may or may not
be passive. The authors of ANTFARM hold no responsibility in how users decide to
gather data they wish to feed into ANTFARM.

## FILES

Unless it already exists, a '.antfarm' directory is created in the current
user's home directory. This directory will contain a default configuration file,
the SQLite3 database used by ANTFARM (if the user specifies for SQLite3 to be
used, which is also the default), and log files generated when using ANTFARM.
Custom plugins created by users will be made available to the ANTFARM
application when they are placed in the '.antfarm/plugins' directory.

Each plugin developed for ANTFARM specifies the input and/or output requirements
when being used. To see what inputs are required for a particular plugin, type:

    $ antfarm help <plugin>

## OPTIONS

ANTFARM's default method of operation is to parse input data or generate output
data using a specified plugin. The plugin to use is specified on the command
line as a sub-command, and each plugin developed specifies it's own required
arguments. Global ANTFARM commands include:

  * `-e`, `--env` <env>:
    The ANTFARM environment to use when executing the given sub-command. The
    default environment is 'antfarm'. Setting the environment variable affects
    things like database used, log file used and configuration settings used.

  * `-l`, `--log-level` <level>:
    The log level used when executing the given sub-command. Optional levels
    include debug, info, warn, error and fatal. The default log level used is
    'warn'.

  * `-v`, `--version`:
    Display the current version of ANTFARM.

  * `-h`, `--help`:
    Display useful help information for ANTFARM.

## EXAMPLES

Display the default help message for ANTFARM:

    $ antfarm -h

    or

    $ antfarm help

Show information about all the plugins currently available in ANTFARM:

    $ antfarm list

Show information specific to an available ANTFARM plugin:

    $ antfarm help <plugin>

Execute an ANTFARM plugin:

    $ antfarm load_host --input-file path/to/host/data.txt

Execute an ANTFARM plugin using a specified environment:

    $ antfarm -e foo load_host --input-file path/to/host/data.txt

Execute an ANTFARM plugin using a specified environment and log level:

    $ antfarm -e foo -l debug load_host --input-file path/to/host/data.txt

## HOMEPAGE

See http://ccss-sandia.github.com/antfarm for more details.

## COPYRIGHT

Copyright (2008-2010) Sandia Corporation. Under the terms of Contract
DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains certain
rights in this software.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, distribute with modifications,
sublicense, and/or sell copies of the Software, and to permit persons to whom
the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or other
dealings in this Software without prior written authorization.
