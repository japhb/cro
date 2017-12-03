use Cro::Tools::CroFile;
use Cro::Tools::Template;
use Cro::Tools::Template::Common;
use META6;

class Cro::Tools::Template::ZeroMQWorkSinkService does Cro::Tools::Template does Cro::Tools::Template::Common {
    method id(--> Str) { 'zeromq-worksink' }

    method name(--> Str) { 'ZeroMQ Work Sink Service' }

    method options(--> List) { () }

    method get-option-errors($options --> List) { () }

    method generate(IO::Path $where, Str $id, Str $name,
                    %options, $generated-links, @links) {
        self.generate-common($where, $id, $name, %options, $generated-links, @links);
    }

    method entrypoint-contents($id, %options, $links) {
        my $env-name = self.env-name($id);
        my $entrypoint = q:to/CODE/;
        use Cro::ZeroMQ::Collector;

        my $worker = Cro::ZeroMQ::Collector.pull(
            connect => "tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>");

        my $work = $worker.Supply.share;

        say "Listening at tcp://%*ENV<MY_TEST_ZMQ_SERVICE_HOST>:%*ENV<MY_TEST_ZMQ_SERVICE_PORT>";
        react {
            whenever $work {
                say $work.perl;
            }

            whenever signal(SIGINT) {
                say "Shutting down...";
                $work.close;
                done;
            }
        }
        CODE
    }

    method cro-file-endpoints($id-uc, %options) {
        Cro::Tools::CroFile::Endpoint.new(
            id => 'zmq',
            name => 'ZeroMQ',
            protocol => 'tcp',
            host-env => $id-uc ~ '_HOST',
            port-env => $id-uc ~ '_PORT'
        ),
    }

    method meta6-depends(%options) { <Cro::ZMQ> }

    method meta6-provides(%options) { () }

    method meta6-resources(%options) { () }
}
