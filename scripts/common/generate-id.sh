#!/bin/bash
declare -a adj=("Red" "Orange" "Yellow" "Green" "Blue" "Purple" "Pink" "Brown" "Gray" "Black" "White" "Silver" "Golden" "Turquoise" "Lavender" "Magenta" "Teal" "Metallic" "Wooden" "Plastic" "Glass" "Ceramic" "Fabric" "Leather" "Synthetic" "Natural" "Synthetic" "Porous" "Durable" "Brittle" "Flexible" "Smooth" "Rough" "Shiny" "Matte" "Textured" "Transparent" "Opaque" "Lightweight" "Heavy" "Resilient" "Fragile" "Elastic" "Sturdy" "Abundant"  "Numerous"  "Copious" "Countless" "Plentiful" "Plenty" "Extensive" "Infinite" "Limitless" "Profuse" "Sufficient" "Adequate" "Scant" "Sparse" "Meager" "Scarce" "Rare" "Minimal" "Modest" "Generous" "Substantial" "Considerable"   "Surplus" "Excessive" "Geometric" "Floral" "Striped" "Dotted" "Checkered" "Paisley" "Abstract" "Symmetrical" "Asymmetrical" "Linear" "Curved" "Wavy" "Herringbone" "Plaid" "Tartan" "Mottled" "Spotted" "Marbled" "Variegated" "Patchwork" "Happy" "Joyful" "Cheerful" "Delighted" "Excited" "Enthusiastic" "Optimistic" "Grateful" "Content" "Pleased" "Thrilled" "Ecstatic" "Elated" "Radiant" "Glowing" "Vibrant" "Energetic" "Playful" "Creative" "Confident" "Brave" "Wise" "Kind" "Compassionate" "Empathetic" "Caring" "Loving" "Affectionate" "Trustworthy" "Honest" "Generous" "Selfless" "Respectful" "Humble" "Gracious" "Charismatic" "Charming" "Friendly" "Sociable" "Outgoing" "Funny" "Witty" "Clever" "Intelligent" "Inspiring" "Motivated" "Ambitious" "Successful" "Accomplished" "Proud" "Squeaky")
declare -a animals=("Aardvark" "Albatross" "Alligator" "Alpaca" "Ant" "Anteater" "Antelope"  "Armadillo" "Donkey" "Baboon" "Badger" "Barracuda" "Basilisk" "Bat" "Bear" "Bee" "Beetle" "Binturong" "Bird" "Boar" "Bobcat" "Buffalo" "Butterfly" "Camel" "Capybara" "Cat" "Cattle" "Centaur"  "Chamois" "Cheetah" "Chicken" "Chimpanzee" "Chinchilla" "Chough" "Coati" "Cobra" "Cod" "Cormorant" "Crab" "Crane" "Cricket" "Crocodile" "Crow" "Curlew" "Deer" "Dinosaur" "Dog" "Dogfish" "Dolphin" "Dove" "Dragon" "Dragonfly" "Duck" "Dunlin" "Eagle" "Echidna" "Elephant" "Elk" "Emu" "Falcon" "Ferret" "Finch" "Fish" "Flamingo" "Fly" "Fox" "Frog" "Gazelle" "Gecko"  "Panda" "Giraffe" "Gnat" "Goat" "Goldfinch" "Goosander" "Goose" "Gorilla" "Goshawk" "Grasshopper" "Grouse" "Guanaco"  "Gull"  "Hare" "Hawk" "Hedgehog" "Heron" "Herring" "Hippo" "Hornet" "Horse" "Hummingbird" "Hyena" "Ibex" "Ibis" "Iguana" "Impala" "Jaguar" "Jay" "Jellyfish" "Junglefowl" "Kangaroo" "Kingbird" "Kinkajou" "Kite" "Koala" "Kraken" "Ladybug" "Lapwing" "Lark" "Lemur" "Leopard" "Lion" "Lizard" "Llama" "Lobster" "Loris" "Louse" "Lyrebird" "Mallard" "Mammoth" "Manatee" "Mandrill" "Manticore" "Mantis" "Meerkat" "Mink" "Mole" "Mongoose"  "Moose" "Mosquito" "Mouse" "Narwhal" "Newt" "Nightingale" "Octopus" "Okapi" "Opossum" "Ostrich" "Otter" "Ox" "Owl" "Owlbear" "Oyster" "Panther" "Parrot" "Partridge" "Peafowl" "Pegasus" "Pelican" "Penguin" "Pheasant" "Pigeon" "Pony" "Porcupine" "Porpoise" "Pug" "Quail" "Rabbit" "Raccoon" "Ram" "Rat" "Raven" "Rhinoceros" "Roc" "Rook" "Salamander" "Salmon" "Sandpiper" "Sardine" "Seahorse" "Seal" "Shark" "Sheep" "Shrew" "Skink" "Skipper" "Skunk" "Sloth" "Snail"  "Sphinx" "Spider" "Spoonbill" "Squid" "Squirrel" "Starfish" "Starling" "Stilt" "Stingray" "Swan" "Tapir" "Tarsier" "Termite" "Thrush" "Tiger" "Toad" "Toucan" "Turtle" "Unicorn" "Viper" "Wallaby" "Walrus" "Wasp" "Weasel" "Whale" "Wildebeest" "Wolf" "Wolverine" "Wombat" "Yeti" "Zebra")

##############
# How to use #
##############
#
# Run the script as is to produce one randomly generated name.
# Optional: pass a number as an argument at the end of the command line to generate that number of names
# Example: To create 10 random names, run 'bash generate-id.sh 10'
#
##############

# produce the number of names requested
for i in $(seq 1 "$1");
do
    # randomly pick a word from the each list
    part1=${adj[ $RANDOM % ${#adj[@]} ]}
    part2=${animals[ $RANDOM % ${#animals[@]} ]}
    # combine the parts
    all_parts=$part1'-'$part2
    # echo and set to lowercase
    echo "$i" - "${all_parts,,}"
done
