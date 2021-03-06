package SdB::App;
use Dancer2;

our $VERSION = '0.1';

get '/DANCER' => sub {
    template 'index' => { 'title' => 'SdB::App' };
};

###
use Dancer2; 
use DBI;
use File::Spec;
use File::Slurper qw/ read_text /;
use Template;

###
my $dbFlag = "DB_CREATED_FILE.txt";

my $database = testForFile($dbFlag);
###

#set 'database'     => File::Spec->catfile(File::Spec->tmpdir(), 'dancr.db');
set 'database'     => File::Spec->catfile(File::Spec->tmpdir(), $database);
set 'session'      => 'Simple';
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;
set 'username'     => 'admin';
set 'password'     => 'password';
set 'layout'       => 'main';

#my $is_file = "/tmp/dancr.db";
#if(! $is_file ){ # Check for DB file.
#       print "DB does not exist.\n Creating!\n";
#       } else {
#       print "DB $is_file exists!\n";
#};

my $flash;

sub set_flash {
    my $message = shift;

    $flash = $message;
}

sub get_flash {
    my $msg = $flash;
    $flash = "";
    return $msg;
}

sub connect_db {
    my $dbh = DBI->connect("dbi:SQLite:dbname=".setting('database')) or
        die $DBI::errstr;
    return $dbh;
}

sub init_db {
    my $db = connect_db();
    my $schema = read_text('./schema.sql');
    $db->do($schema) or die $db->errstr;
}

hook before_template_render => sub {
    my $tokens = shift;
    $tokens->{'css_url'} = request->base . 'css/style.css';
    $tokens->{'login_url'} = uri_for('/login');
    $tokens->{'logout_url'} = uri_for('/logout');
};

get '/' => sub {
    my $db = connect_db();
    my $sql = 'select id, parent, category, title, text from entries order by id desc';
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute or die $sth->errstr;
    template 'show_entries.tt', {
        'msg' => get_flash(),
        'add_entry_url' => uri_for('/add'),
        'entries' => $sth->fetchall_hashref('id'),
    };
};

post '/add' => sub {
    if ( not session('logged_in') ) {
        send_error("Not logged in", 401);
    }

    my $db = connect_db();
    my $sql = 'insert into entries (parent, category, title, text) values (?, ?, ?, ?)';
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute(params->{'parent'},params->{'category'},params->{'title'}, params->{'text'}) or die $sth->errstr;

    set_flash('New entry posted!');
    redirect '/';
};

any ['get', 'post'] => '/login' => sub {
    my $err;

    if ( request->method() eq "POST" ) {

        if ( params->{'username'} ne setting('username') ) {
            $err = "Invalid username";
        }
        elsif ( params->{'password'} ne setting('password') ) {
            $err = "Invalid password";
        }
        else {
            session 'logged_in' => true;
            set_flash('You are logged in.');
            return redirect '/';
        }
   }

   template 'login.tt', {
       'err' => $err,
   };
};

get '/logout' => sub {
   app->destroy_session;
   set_flash('You are logged out.');
   redirect '/';
};

init_db();
start;
###

true;

### SUBS

sub testForFile {
 my($filename) = @_;
 my $uniqueDbName;
  print "Filename: $filename.\n";
  if (-f $filename) {
    print "File Exists!\n";
    open (my $fh, "$filename");
    my $line = <$fh>;
    $uniqueDbName = $line;
    print "DB name: $uniqueDbName.\n";
  } else {
    print "File does not exist. Making $filename\n";
    $uniqueDbName = createUniqueDbName();
    openFile($filename,$uniqueDbName);
  }
  return($uniqueDbName);
}

sub openFile {
  my($filename,$uniqueDbName) = @_;
  open( my $fh, ">","$filename") || die "Flaming death on creation of DB Flag file:$!\n";
  print "File open!\n";
  print $fh "$uniqueDbName\n";
  close $fh;
}

sub createUniqueDbName {
  my $time = time(); 
  my $rand = int(rand(10)); 
  my $name = "dancr_".$time.$rand.".db"; 
  print $name, "\n\n"; 
  return($name);
};



###
