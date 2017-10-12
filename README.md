# PDE Blue Badge Demo

This repository is a demonstration of the capabilities of the AQuAE system as applied to an eligibility checker scenario.

The demonstration implements an eligibility checker designed for use by a caseworker that accepts a citizen's identity data and dispatches a question via an integrated AQuAE node. The federation of nodes co-operate to answer the query, and the discovered eligibility is displayed to the user.

It is important to stress that this prototype is designed for demonstration of the AQuAE components alone - as such, the security features that would be necessary for a live service are not implemented here. See the [specification](https://www.github.com/alphagov/pde-specification) for more details on operation of the network.

## Blue Badge

Local authorities are required to administer the provision of [Blue Badges](https://www.gov.uk/apply-blue-badge), which are parking permits for those with accessibility needs that allow the holder to park in specially marked parking spaces.

In order to receive a Blue Badge, a citizen must have an accessibility need. This can be shown through a physical assessment, or can be established using other information held by Government. There are five eligibility criteria that allow automatic proof, of which the most commonly used are receipt of Personal Independence Payment (PIP) or receipt of Disability Living Allowance (DLA).

## Federation

The demonstration supposes a federation of the following structure:

* A database containing PIP data, serving a question about a citizen's PIP score.
* A database containing DLA data, serving a question about a citizen's rate of DLA.
* An intermediate node, run by owner of the Blue Badge eligibility rules, that implements the Blue Badge query.
* A web client node that asks the Blue Badge query as requested by the web application.

The other automatic criteria are not considered in this demo, but adding the extra criteria would be a simple scaling of the Blue Badge query to incorporate the additional data sources.

As a diagram:

     +----------+              +---------------+                           +----------+
     | Web Node | --[ bb? ]--> | BB Query Node | --------[ pip>8? ]------> | PIP Node |
     +----------+              +---------------+ \                         +----------+
                                                  \
                                                   \                       +----------+
                                                    \--[ dla-higher? ]-->  | DLA Node |
                                                                           +----------+

## Demonstration

This demo presents an eligibility checker prototype that has been used to do research with service providers. Entering identity information will send a query through the network and return an eligibility result, which is then displayed.

### Operating the Demo

You will need to have a modern Ruby installed to run the AQuAE softare and serve the web front-end.

The prototype front-end is based on the GOV.UK prototype kit and must be transpiled from Nunjucks into Liquid, so you will also need a modern Node.js installed to run the transpiler.

Commands below will achieve the desired effect on a POSIX shell. The demonstration also supports Windows and PowerShell perfectly fine.

1. Install the dependencies and check out the required repositories.

        $ bundle install
        $ git submodule init

2. Generate the necessary supporting files. This will copy all of the necessary content from the prototype repository and generate the config files necessary.

        $ bundle exec rake prototype config

3. Run the federation. The easiest way to use this is by using the `bluebadged` binary. This will launch the necessary nodes on the local machine. The federation can be disbanded by sending an interrupt signal.

        $ bundle exec ruby ./bin/bluebadged

    You could also run the individual components seperately.

        $ bundle exec ruby ./bin/prototypes ./bb-web-client.config.yml &
        $ bundle exec whirlpoold ./bb-query-server.config.yml &
        $ bundle exec whirlpoold ./bb-da.pip.config.yml &
        $ bundle exec whirlpoold ./bb-da-dla.config.yml &

4. Open a web browser to http://localhost:4567/.

## Playback

The prototype will also render a query playback tool at http://localhost:4567/demo. This shows the federation used in the prototype and the links between the nodes.

It can also replay log output and show the way in which messages move through the system. Pasting log output from each of the Whirlpool processes into the box will allow the playback to be stepped through, and will show the state at each node using symbols. The arrow buttons in the bottom left can step through the messages.

Log messages can be combined from the demo using:

    $ cat *.log.txt > full-log.txt

The replayer will parse and automatically order the log messages according to time, so they can be pasted in any order.