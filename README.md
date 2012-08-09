# SO2DB
SO2DB provides an API for importing the Stack Overflow/Stack Exchange data dumps into a database. It also provides a PostgreSQL import utility (so2pg) out of the box.


# Using the PostgreSQL Import Utility
1.  Download a [Stack Exchange Data Dump](http://www.clearbits.net/creators/146-stack-exchange-data-dump) and extract the data set that you want to import (e.g., math.stackexchange.com.7z).

2.  Strip invalid XML-encoded strings from the extracted XML files.  This is a [known issue](http://blog.stackoverflow.com/2009/06/stack-overflow-creative-commons-data-dump/#comment-24223).  I have a [Gist](https://gist.github.com/3270224) you can use that backs up and cleans all the XML files in a directory.

3.  Ensure that you have the PostgreSQL client (`psql`) installed.  `psql` is used to bulk copy data into your database.

4.  Create a PostgreSQL database for the data.

5.  Install SO2DB with the command `gem install so2db`.  You may have to use `sudo` depending on your setup.

6.  Call so2pg to import the data with the command `so2pg -O -R -d db_name -D /path/to/data/dir`.  The data directory is the directory containing the clean XML files.  The -O and -R flags indicate that you wish to include optional tables and table relationships, respectively. You can see all the options by running `so2pg --help` or in the list below. 

7.  Wait impatiently!  Depending on your hardware and the data set you choose to import, `so2pg` may take a while to run.  With all that free time on your hands, why don't you help me figure out how to make so2db *faster?!*


## so2pg options

        -H --host HOST               The database host

        -d --database DBNAME         The name of the database (REQUIRED)

        -D --directory DIRECTORY     The data directory path (REQUIRED)

        -u --user USER               The user name
 
        -p --password PASSWORD       The user's password

        -P --port PORT_NUMBER        The port number
 
        -O --include-optionals       Includes optional tables

        -R --include-relationships   Includes table relationships
      
        -h --help                    Show this help screen
        
## Learning PostgreSQL?
Be sure to check out the Tekpub [Hello PostgreSQL](http://tekpub.com/productions/pg) series.  It presents a lot of useful information quickly and in an accessible manner.  I built this gem simply so I could practice along with the videos.  Highly recommended! 

## Hardware and Performance
We have run so2pg several times on two machines with slightly hardware configurations.  The CPUs and RAM were comparable (2.66 vs. 2.4 GHz, 4GB RAM), but one had an SSD while the other had a ...slow... HD.  When importing the Apr 2012 Stack Overflow dump on each machine, we noticed about 43% faster import times on the SSD (2 hrs vs. 3.5 hrs).

Your import may take quite some time to complete, and the performance is very dependent on your hard drive speed.

## Other Tips
If you are running `so2pg` on OS X, you may want to run the `purge` command in a terminal periodically.  This will free up "Inactive Memory" and reduce the number of pages to disk.  This should help performance, though I haven't specifically made measurements on it. 


# Creating a Custom Importer
Before you create your own custom importer, you should check to see if someone is already working on one with the same purpose.  Otherwise, let us know what you're working on and get started!

SO2DB depends on ActiveRecord and [Foreigner](https://github.com/matthuhiggins/foreigner) to build tables and relationships, and so SO2DB is limited to the databases supported by both projects.  (At the time of writing, Foreigner only supports PostgreSQL, MySQL, and SQLite.  ActiveRecord supports these and more.)  

Creating a custom importer requires you to provide two classes: an ActiveRecord monkey patch and the importer implementation.

First, you need to create a [monkey patch](http://stackoverflow.com/questions/394144/what-does-monkey-patching-exactly-mean-in-ruby) that adds a uuid method to the associated ActiveRecord connection adapter.  The uuid method defines the database type associated with a universally unique identifier (e.g., 'uuid' in PostgreSQL, 'CHAR(16)' in MySQL).

Next, you must create a subclass of SO2DB::Importer that contains a method with the following definition:

> import_stream(formatter)

The formatter will be a SO2DB::Formatter, which generates formatted output from a StackOverflow XML data file when you call the its `format` method.  The `format` method accepts a stream and pumps formatted data to that stream.  This approach allows for you to deal with the data as you see fit - pass it over STDIN to another command (this is what so2pg does) or send it to a file that you then pass to a database system.  If you need the database parameters provided to SO2DB, they are provided in the importer conn_opts property.

The data coming from the formatter will use a delimiter specified in the Importer implementation.  A vertical tab, '\v' (0xB), is used by default.  This can be changed by setting the format_delimiter property in the importer.

The formatter also offers a couple of convenience routines, `file_name` and `value_str`. `file_name` simply provides the name of the file to be formatted.  `value_str` provides a partial SQL string based on the data to be formatted.  It provides the table name and the ordered value names associated with the formatted data.  For example, assume you are provided a formatter for badges.xml.  The convenience routines produce the following:

```ruby
puts formatter.file_name
# => badges.xml

puts formatter.value_str
# => badges(id,date,name,user_id)
```

Note that the field names are alphabetized.  The field values from the formatter will have the same ordering.  This is to ensure consistent and predictable field ordering, even if fields are not provided in the XML file.  If a field is not provided in the XML file, an empty string is inserted into the formatted data.

I encourage you to check out the implementation of so2pg if you are interested in developing your own importer; there are additional notes throughout the source to make your development experience a bit smoother.

When you are finished, consider creating a pull request.  I would love to include your labor of love in a future release!

# License
SO2DB is released under the [MIT License](http://opensource.org/licenses/MIT).


# Tested Platforms
This project has been tested under OS X (Snow Leopard) and Ubuntu 12.04 using Ruby version 1.9.2 and 1.9.3.  If anyone wants to test on other platforms, I would appreciate it!


# Supported Data Dumps
SO2DB has been tested against the following data dumps:

    Sept 2011
    Apr  2012

# Special Thanks
Thanks to [@nclaburn](https://github.com/nclaburn) for being a great mentor and helping me get this project released!
