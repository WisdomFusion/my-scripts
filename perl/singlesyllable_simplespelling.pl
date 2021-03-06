use 5.12.0;

use utf8;
use open ':std', ':encoding(UTF-8)';

use Socket qw(:DEFAULT :crlf);
use Data::Dump qw(dump);

my $ref_vowel_combs = {
    ought => 'iught',
    eigh  => 'aigh',
    ture  => 'true',
    air   => 'ear',
    ale   => 'ile',
    all   => 'oll',
    are   => 'eer',
    aur   => 'all',
    eal => 'ill',
    ear => 'are',
    eer => 'ear',
    eir => 'are',
    ere => 'ear',
    ial => 'oul',
    ier => 'eer',
    igh => 'egh',
    ing => 'eng',
    ire => 'are',
    oal => 'all',
    oar => 'all',
    oll => 'all',
    ool => 'oal',
    oor => 'all',
    ore => 'all',
    oul => 'ool',
    our => 'all',
    ure => 'rue',
    ai => 'ei',
    al => 'ol',
    ar => 'ir',
    au => 'ou',
    aw => 'au',
    ay => 'ey',
    ea => 'ee',
    ee => 'ea',
    ei => 'ea',
    er => 'or',
    eu => 'au',
    ew => 'aw',
    ey => 'ay',
    ie => 'ei',
    ir => 'er',
    oa => 'ou',
    oi => 'io',
    ol => 'al',
    oo => 'ou',
    or => 'er',
    ou => 'au',
    ow => 'aw',
    oy => 'oi',
    ue => 'eu',
    ui => 'ue',
    ur => 'ir',
    uy => 'ey',
};

# 元音因素对应的字母组合
my @vowel_combs = qw( ai air al ar are au aur aw ay ea ear ee eer ei eigh eir er ere eu ew ey ie igh ing ir ire oa oar oi ol oo oor or ore ou ought oul our ow oy ture ui ur ure uy eal ool oal oll ier ale all ial ue );

# 辅音音素对应的字母组合
my @consonant_combs = qw( ch ck dd dge dj dr ds ff gh ght gn gu gue kn ll mm mn ng nn ph pp qu sc sh sion ss sure tch th the tion tr ts tt wh wr ssion );

# 元音音素对应的字母
my @vowels = qw( a e i y o u );

my $str_vowels = join '', @vowels;

# 辅音音素对应的字母
my @consonants = qw( b c d f g h j k l m n p q r s t v w x y z );

my $str_consonants = join '', @consonants;

my @sorted_vowel_combs     = sort { length $b <=> length $a } ( sort @vowel_combs );     # 先长度后字母排序
my @sorted_consonant_combs = sort { length $b <=> length $a } ( sort @consonant_combs ); # 先长度后字母排序
my @sorted_vowels          = sort @vowels;
my @sorted_consonants      = sort @consonants;

#say join "\n", @sorted_vowel_combs;
#say join "\n", @sorted_consonant_combs;
#say join "\n", @sorted_vowels;
#say join "\n", @sorted_consonants;

my @all_combs = ( @sorted_vowel_combs, @sorted_consonant_combs, @sorted_vowels, @sorted_consonants );

#say dump @all_combs;
#say join "\n", @all_combs;

while ( <DATA> ) {
    chomp;
    
    my $word = $_;
    
    my $result_word  = ''; # 结果单词
    my $matched_chas = ''; # 匹配的字母（组合）
    my $mark         = '';
    
    # 元音因素对应的字母组合
    foreach my $vowel ( @sorted_vowel_combs ) {
        # 不全挖
        next if length $word == length $vowel;
        
        if ( $word =~ /$vowel/i ) {
            $mark = '_' x length $vowel;
            
            $result_word = $word;
            $result_word =~ s/$vowel/$mark/ie;
            
            print $word, "\t", $result_word, $LF;
            
            goto LABEL;
        }
    }
    
    # 元音辅音e
    if ( $word =~ /([aeiou])[bcdfghjklmnpqstvwxyz]e/i ) {
        $result_word = $word;
        $result_word =~ s/[aeiou]([bcdfghjklmnpqstvwxyz])e/_$1_/i;
        
        print $word, "\t", $result_word, $LF;
        
        goto LABEL;
    }
    
    # 辅音音素对应的字母组合
    foreach my $consonant ( @sorted_consonant_combs ) {
        # 不全挖
        next if length $word == length $consonant;
        
        if ( $word =~ /$consonant/i ) {
            $mark = '_' x length $consonant;
            
            $result_word = $word;
            $result_word =~ s/$consonant/$mark/ie;
            
            print $word, "\t", $result_word, $LF;
            
            goto LABEL;
        }
    }
    
    # 元音音素对应的字母
    foreach my $vw ( @sorted_vowels ) {
        # 不全挖
        next if length $word == length $vw;

        next if $vw eq 'e';
        
        if ( $word =~ /$vw/i ) {
            $mark = '_';
            
            $result_word = $word;
            $result_word =~ s/$vw/$mark/ie;
            
            print $word, "\t", $result_word, $LF;
            
            goto LABEL;
        }
    }
    
    # 辅音音素对应的字母
    foreach my $co ( @sorted_consonants ) {
        # 不全挖
        next if length $word == length $co;
        
        if ( $word =~ /$co/i ) {
            $mark = '_';
            
            $result_word = $word;
            $result_word =~ s/$co/$mark/ie;
            
            print $word, "\t", $result_word, $LF;
            
            goto LABEL;
        }
    }
    
    LABEL:
    ;
}

__DATA__
Athelney
blare
blaze
blot
blur
boast
bogged
boo
burgle
butt
churn
clamp
cleft
clog
cod
cramped
creep
crest
crude
cursed
Dane
deem
dredge
flint
flirt
forth
framed
fuse
gel
gilt
glimpse
glint
glisten
grapple
grass-seed
grease
grid
grip
grudge
gust
handyman
hardened
haul
haunt
heath
heave
hive
hobble
horde
hub
hull
jibe
lamp-post
lash
latch
locks
lodge
loom
lull
lure
lurk
mere
mirth
moot
mournful
muffle
mumble
muzzle
nag
naval
odds
pact
pence
perch
plank
plea
plead
ply
pounce
prise
prudent
resin
run-down
scalp
scorn
screw
scrub
seasons
shoal
silt
slur
smash-and-grab
snag
sneer
snob
snout
soothe
spawn
squall
stale
steer
steps
stole
stoves
straggle
stray
stroll
swarm
taunt
thresh
thrive
throng
tint
trickle
triple
tuck
tussle
vie
vinyl
vole
volt
wade
wane
wares
weird
whine
winch
winkle
wreck
wriggle
yeast
