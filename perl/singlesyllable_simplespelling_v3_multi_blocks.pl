use 5.12.0;

# 多音节拼读数据，用于简拼题型的挖空和干扰的生成

use utf8;
use open ':std', ':encoding(UTF-8)';

use Socket qw(:DEFAULT :crlf);
use Data::Dump qw(dump);

# 元音因素对应的字母组合
my $vowel_combs_ref = {
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

# 辅音音素对应的字母组合
my $consonant_combs_ref = {
    ssion => 'ation',
    sion => 'tion',
    sure => 'ture',
    tion => 'sion',
    dge => 'gue',
    ght => 'igh',
    gue => 'que',
    tch => 'che',
    the => 'she',
    ch => 'sh',
    ck => 'sk',
    dd => 'de',
    dj => 'dg',
    dr => 'tr',
    ds => 'dz',
    ff => 'ph',
    gh => 'ph',
    gn => 'gu',
    gu => 'gi',
    kn => 'nk',
    ll => 'il',
    mm => 'mn',
    mn => 'nm',
    ng => 'gn',
    nn => 'nm',
    ph => 'ff',
    pp => 'ph',
    qu => 'kw',
    sc => 'ss',
    sh => 'ch',
    ss => 'sc',
    th => 'sh',
    tr => 'dr',
    ts => 'tz',
    tt => 'te',
    wh => 'wr',
    wr => 'wh',
};

# 元音音素对应的字母
my @vowels = qw( a e i y o u );

my @aeu = qw( a e u );

my @iy = qw( i y );

# 辅音音素对应的字母
my $consonants_ref = {
    b => 'p',
    c => 'k',
    d => 'b',
    f => 'v',
    g => 'j',
    h => 'n',
    j => 'g',
    k => 'c',
    l => 'r',
    m => 'n',
    n => 'm',
    p => 'b',
    q => 'k',
    r => 'l',
    s => 'z',
    t => 'd',
    v => 'w',
    w => 'v',
    x => 's',
    y => 'i',
    z => 's',
};

while ( <DATA> ) {
    chomp;
    
    #两个音节-挖前面音节（若前面只有一个或两个字母，则挖后面一个音节）
    #三个音节-挖前面两个音节：主要考察词根
    #四个音节-挖后面两个音节：主要考察一部分词根及词缀
    #五个音节及以上-挖后面三个音节：主要考察一部分词根及词缀
    
    my $phonics = $_;
    my @phonics_blocks = split /\-/, $phonics;
    my $phonics_block_num = scalar @phonics_blocks;
    my $word = $phonics;
    $word =~ s/\-//g;
    
    my $phonics_blank = '';
    my $phonics_alter = '';
    
    if ($phonics_block_num == 1) {
        ;
    }
    elsif ($phonics_block_num == 2) {
        if (length $phonics_blocks[0] <= 2) {
            $phonics_blank = $phonics_blocks[1];
        }
        else {
            $phonics_blank = $phonics_blocks[0];
        }
        
        $phonics_alter = &trim_phonics_block($phonics_blank);
    }
    elsif ($phonics_block_num == 3) {
        $phonics_blank = $phonics_blocks[0] . $phonics_blocks[1];
        $phonics_alter = &trim_phonics_block($phonics_blocks[0]) . &trim_phonics_block($phonics_blocks[1]);
    }
    elsif ($phonics_block_num == 4) {
        $phonics_blank = $phonics_blocks[2] . $phonics_blocks[3];
        $phonics_alter = &trim_phonics_block($phonics_blocks[2]) . &trim_phonics_block($phonics_blocks[3]);
    }
    else {
        $phonics_blank = $phonics_blocks[$phonics_block_num - 3] . $phonics_blocks[$phonics_block_num - 2] . $phonics_blocks[$phonics_block_num - 1];
        $phonics_alter = &trim_phonics_block($phonics_blocks[$phonics_block_num - 3]) . &trim_phonics_block($phonics_blocks[$phonics_block_num - 2]) . &trim_phonics_block($phonics_blocks[$phonics_block_num - 1]);
    }
    
    say $phonics, "\t", $phonics_blank, "\t", $phonics_alter;
}

sub trim_phonics_block {
    
    my $block = shift;
    
    my $result_word   = ''; # 结果单词
    my $matched_chars = ''; # 匹配的字母（组合）
    my $alter_chars   = '';
    
    # 元音因素对应的字母组合
    foreach my $vowel ( sort { length $b <=> length $a } ( sort keys %$vowel_combs_ref ) ) {
        if ( $block =~ /$vowel/i ) {
            $result_word = $block;

            $matched_chars = $vowel;
            $alter_chars   = $vowel_combs_ref->{$vowel};
            $result_word   =~ s/$vowel/$alter_chars/ie;
            
            return $result_word;
        }
    }
    
    # 元音+辅音+e
    if ( $block =~ /([aeiou])[bcdfghjklmnpqstvwxyz]e/i ) {
        my $current_vw = $1;
        
        my $vowels  = 'aeiou';
        my $rest_vw = $vowels;
        $rest_vw    =~ s/$current_vw//i;
        my @rest_vw = split '', $rest_vw;
        
        $result_word = $block;
        
        $matched_chars = $current_vw . '_e';
        $alter_chars   = $rest_vw[ int rand scalar @rest_vw ];
        $result_word   =~ s/[aeiou]([bcdfghjklmnpqstvwxyz])e/$alter_chars$1e/i;
    
        return $result_word;
    }
    
    # 辅音音素对应的字母组合
    foreach my $consonant ( sort { length $b <=> length $a } ( sort keys %$consonant_combs_ref ) ) {
        if ( $block =~ /$consonant/i ) {
            $result_word = $block;
            
            $matched_chars = $consonant;
            $alter_chars   = $consonant_combs_ref->{$consonant};
            $result_word   =~ s/$consonant/$alter_chars/ie;
            
            return $result_word;
        }
        
    }
    
    # 元音音素对应的字母
    foreach my $vw ( @aeu ) {
        
        if ( $block =~ /$vw/i ) {
            $result_word = $block;
            
            my $vowels  = 'aeu';
            my $rest_vw = $vowels;
            $rest_vw    =~ s/$vw//i;
            my @rest_vw = split '', $rest_vw;
        
            $matched_chars = $vw;
            $alter_chars   = $rest_vw[ int rand scalar @rest_vw ];
            $result_word   =~ s/$vw/$alter_chars/ie;
            
            return $result_word;
        }
    }
    
    foreach my $vw ( @iy ) {
        
        if ( $block =~ /$vw/i ) {
            $result_word = $block;
            
            my $vowels  = 'iy';
            my $rest_vw = $vowels;
            $rest_vw    =~ s/$vw//i;
            my @rest_vw = split '', $rest_vw;
        
            $matched_chars = $vw;
            $alter_chars   = $rest_vw[ int rand scalar @rest_vw ];
            $result_word   =~ s/$vw/$alter_chars/ie;
            
            return $result_word;
        }
    }
    
    if ( $block =~ /o/i ) {
        $result_word = $block;
        
        my @vw = split '', 'au';
        $alter_chars = @vw[ int rand scalar @vw ];
        $result_word =~ s/o/$alter_chars/ie;
        
        return $result_word;
    }
    
    # 辅音音素对应的字母
    foreach my $co ( sort keys %$consonants_ref ) {
        if ( $block =~ /$co/i ) {
            $result_word = $block;
            
            $matched_chars = $co;
            $alter_chars   = $consonants_ref->{$co};
            $result_word   =~ s/$co/$alter_chars/ie;
            
            return $result_word;
        }
    }
    
    LABEL:
    ;
    
}

__DATA__
a-bate-ment
a-be-rrant
ab-ject
a-blaze
ab-sorb-ing
ab-struse
ab-surd-ly
a-ccom-pa-ni-ment
a-ccord
a-ci-dic
a-cro-bat-ic
ac-tu-a-li-ty
a-da-mant
a-dder
ad-mit-ted-ly
a-dorn
ad-vent
ad-verse
ad-vi-so-ry
Ae-ge-an
ae-ri-al
aes-the-tic
a-ffec-tion-ate
a-fflict
a-fflu-ent
a-fresh
age-ing
a-ggra-vate
a-go-niz-ing
air-re-sist-ance
al-ba-tross
a-li-bi
a-li-en-ate
a-lle-ga-tion
Al-pine
al-pi-nist
a-mass
am-ply
a-na-log-ous
a-nar-chy
a-ni-mals
an-te-nna
an-xious-ly
a-phid
a-po-lo-ge-tic
a-qua-plane
ar-chi-tec-tur-al
ar-du-ous
a-ris-to-crat
ar-ma-ment
arse-nic
art-iste
a-scer-tain
a-ssail
a-ssi-du-ous-ly
a-ssort-ed
as-te-risk
a-stound
as-tro-no-mic-al
au-tho-ri-ta-rian
back-wa-ter
bac-te-ri-cid-al
ba-llast
ba-nal
bar-ba-rian
ba-ttered
bear-ing
be-draggled
bees-wax
be-queath
be-wil-der
be-wil-der-ment
bit-ing
black-berry
blan-dish-ment
blind-fold
bli-zzard
blue-bo-ttle
blush-ing
bold-ly
bomb-er
book-shelf
bould-er
bri-gade
bro-ker
bull-fight
bu-lli-on
bul-rush
buo-y
bur-row
bus-man
call-er
ca-nnon
ca-price
cap-size
car-bon-at-ed
car-ni-vore
ca-rriers
ca-scade
ca-ta-stroph-ic
ca-vern
cease-less-ly
cell-ar
cen-sus
cham-ber-maid
cha-sm
check-er
che-rish
che-rub
chi-ca-ne-ry
ci-ty-state
ci-vil-ize
clat-ter
cla-vi-chord
cle-ric-al
clothes-line
clu-ster
clu-tter
co-bra
cock-crow
co-llide
co-lo-ssal
co-lour-blind
com-bat-ive
co-mmer-cial-i-za-tion
co-mmi-ssa-ri-at
co-mmi-ssion
co-mmo-di-ty
com-pact
com-part-ment
com-po-sure
com-pound
con-ceit-ed
con-coct
con-coc-tion
con-jur-ing
con-quer-or
con-sci-en-tious
con-sole
con-spi-re
con-sta-ble
con-sti-tute
con-struct-ive-ly
con-ta-mi-nate
con-ta-mi-na-tion
con-tempt
con-tent-ed
con-ten-tion
con-tents
con-tri-vance
con-ver-sion
con-ver-ti-ble
con-voy
con-vuls-ive
co-rre-spond-ing-ly
cos-me-tic
cos-mic
coun-ter-act
coun-tries
crack-ers
cre-dit-or
cre-du-lous
cre-vasse
crock-e-ry
cruis-er
cul-pa-ble
cur-a-tive
cu-stod-ian
cus-tom-ize
cy-lind-er
cyn-ic
daw-dle
de-bit
debt-or
de-com-pose
de-duce
de-fend-ant
de-lin-quen-cy
de-lu-sion
de-mon
de-rrick
de-so-late
de-spise
de-va-sta-tion
de-vi-ation
de-vou-r
di-ag-nos-is
di-a-lys-is
di-gest-ive
di-la-pid-at-ed
din-ghy
di-scard
di-scern
dis-cre-dit
dis-creet-ly
dis-em-bark
dis-grace
dis-i-llu-sion
dis-i-llu-sion-ment
dis-in-fect-ant
dis-in-he-rit
dis-lo-cate
dia-loy-al-ty
dis-man-tle
di-spel
dis-re-gard
dis-taste-ful
di-stin-guished
dis-u-nit-ed
dis-used
di-ver-sion
do-mes-tic-ate
door-knob
down-fall
drain-age
drear-y
drift-ing
dri-ly
du-bi-ous
du-plic-ate
dust-er
dust-man
dwell-er
ec-cen-tri-ci-ty
e-ddy
e-di-fice
ee-rie
e-go
e-lec-tion
e-lec-tro-cute
e-lec-trode
em-bed-ded
e-mi-nent
e-mit
e-mo-tion-a-lly
em-ploy-ees
en-croach-ing
en-dear-ing
e-ner-gize
en-sue
en-tail
en-tranced
en-vi-sion
e-pi-thet
e-qui-li-brium
e-rode
es-ca-la-tor
e-scap-ist
es-pion-age
e-ter-nal
e-tha-nol
e-vade
ex-a-min-er
ex-cep-tion-a-lly
ex-clus-ive
ex-clus-ive-ly
ex-cu-ses
ex-empt
ex-er-cis-es
ex-hi-la-rat-ing
ex-pe-ri-ments
ex-qui-site
ex-ter-mi-nate
ex-tol
fa-ci-li-tate
faint-ly
falt-er
fa-na-tic-al
fan-ci-ful
fa-tu-ous
fault-y
fe-line
fer-ment
fer-vent-ly
fi-ckle-ness
fi-ssure
flag-ship
flea-ri-dden
flick-er
fluc-tu-a-tion
fore-fa-thers
fore-man
fore-sight
fore-tell
for-mi-da-ble
for-tune-tell-er
foun-da-tions
frac-tion
frag-ment
fran-tic-ally
fres-co
fre-shen
fright-ful
fri-tter
fum-ble
fun-da-ment-als
fuss-y
fu-tile
ga-lle-on
gangs-ter
gao-ler
gene-ral-ize
ge-sti-cu-late
glid-er
good-hu-moure-dly
grand-pa-rents
gra-ti-fy
gra-vi-ta-tion-al
grey-ish
grim-ly
grow-er
guest-room
guilt-i-ly
gush-er
hae-mo-ly-tic
ham-per
ha-rry
haw-ser
head-light
head-y
he-re-tic
he-rring
hi-e-rarch-y
high-hand-ed
hind-er
hitch-hike
horse-pow-er
ho-ver-craft
ho-ver-train
hu-mid-i-ty
hur-ried-ly
hyp-no-tize
hy-po-cri-sy
hy-po-the-sis
i-dyll-ic
ig-no-ble
i-lli-te-rate
i-llo-gic-al
i-llu-mi-na-tion
i-mma-cu-late
i-mmens-i-ty
i-mmo-la-tion
i-mmor-tal
im-pend-ing
im-per-cep-ti-ble
im-per-son-al
im-po-ver-ish
im-pro-ba-ble
in-ac-ce-ssi-ble
in-ce-ssant-ly
in-ci-dent-ally
in-cle-ment
in-cli-na-tion
in-con-ceiv-able
in-cum-bent
in-cur
in-de-fin-a-ble
in-de-scrib-a-ble
in-dig-ni-ty
in-di-scri-mi-nate
in-dis-po-si-tion
in-dus-trious-ness
in-e-vi-ta-bly
in-fa-lli-bi-li-ty
in-fant
in-fi-nite-ly
in-fi-nit-y
in-flat-a-ble
in-ge-nu-i-ty
in-most
in-no-vat-or
in-quire
in-rush
in-si-di-ous
in-si-nu-ate
in-sist-ent
in-so-lu-ble
in-su-la-ri-ty
in-sur-moun-ta-ble
in-te-grat-ed
in-ter-fer-ence
in-ter-mi-na-bly
in-ter-mit-tent
in-ter-ste-llar
in-ter-weave
in-ti-ma-tion
in-ti-mi-date
in-tox-i-cate
in-trigue
in-trud-er
in-va-ri-abl-y
in-ven-to-ry
in-ve-te-rate
i-ro-nic-ally
jerk-y
jig-saw
junc-ture
jus-ti-fi-ca-tion
ju-ve-nile
Ka-ra-te
kid-nap-per
kind-ly
la-bour-er
la-by-rinth
large-ly
laun-de-rette 
la-vish-ly
leak-age
learn-er
le-gi-bl-y
light-house
like-li-hood
like-mind-ed
lime-light
li-nen
li-ner
li-ste-ria
lob-ster
lon-gi-tudi-nal
lo-tto
lu-scious
ma-ca-ro-ni
mag-net-ize
mag-ni-tude
ma-hout
maid-ser-vant
main-frame
ma-jes-tic
mam-ba
ma-ni-a
ma-ni-fest
ma-noeu-vre
mar-quis
ma-ta-dor
ma-ttress
ma-tur-i-ty
me-mo-ry-chip
mer-maid
me-te-o-ro-lo-gist
me-thy-lat-ed
mi-ddle-aged
mi-lo-me-ter
min-strel
mi-ra-cu-lous-ly
mo-na-ste-ry
mo-no-ton-ous
mon-strous
mor-tal-ly
mo-tion-less
mu-ni-ci-pal-i-ty
mu-ster
mu-ti-late
my-riad
my-xo-ma-to-sis
na-ive
na-rrow-ly
ne-bu-la
neg-li-gence
neg-li-gi-ble
neu-ro-tox-ic
new-ly-weds
news-a-gent
news-le-tter
nine-pin
non-fic-tion
no-stril
no-to-rious-ly
no-vice
oar-fish
o-blige
ob-scu-ri-ty
ob-serv-ant
ob-sti-nate-ly
ob-struc-tion
o-ccur-rence
o-cea-na-ri-um
oc-to-pus
odd-ly
o-ffend-er
o-ffi-cious
o-kay
om-buds-man
o-men
o-mi-nous-ly
o-paque
o-ppo-nent
o-ppress
ord-nance
or-ga-nic-ally-grown
or-gy
o-ri-ent-al
or-pha-nage
out-land-ish
out-ra-geous
co-ver-alls
o-ver-ba-lance
o-ver-heads
o-ver-in-du-strial-ized
o-ver-land
o-ver-po-pu-lat-ed
o-ver-run
o-ver-whelm
o-ver-whelm-ing-ly
o-ver-zea-lous-ly
pack-ing
pa-gan
pain-less-ly
pa-lae-on-to-lo-gic-al
pa-ra-dise
pa-ra-troop-er
pa-ri-shion-er
par-lia-men-tary
par-quet
par-tridge
pa-ssion-ate-ly
pa-sto-ral
pa-stry
pas-ture
pa-tron-age
pe-de-stal
pe-nal-ize
pen-hold-er
pe-nnant
pe-ril-ous
per-pe-tual
per-se-cute
per-sist-ent
per-spi-re
per-spi-r-ing
perti-nent
per-turb
pest-er
pes-ti-lence
pe-tri-fy
phe-no-me-na
phrase-book
phy-si-o-lo-gi-cal
pit-fall
plau-si-ble
plead-ing
plea-sant-ly
plu-mber
pneu-mat-ic
po-cket-book
po-lo
por-cu-pine
Por-tu-guese
po-si-tive-ly
po-ten-cy
po-ten-ti-a-li-ty
pot-hol-er
pot-hol-ing
preach-er
pre-ca-rious-ly
pre-de-ce-ssor
pre-do-mi-nant
pre-fe-ren-tial
pre-ju-diced
pre-lude
pre-mise
pre-mis-es
pre-pon-de-rance
pre-side
pre-sump-tu-ous
pre-ten-tious
pre-vail-ing
pris-tine
prize-fight-er
pro-ce-ssion
pro-longed
pro-mis-cu-ous
pro-pul-sion
pro-se-cute
pro-ta-gon-ist
pro-vo-ca-tion
psy-chi-a-tric
psy-chi-a-trist
pu-ma
punc-tu-a-li-ty
punc-tu-al-ly
punc-tu-ate
punc-ture
pur-chas-a-ble
qui-cken
quin-tu-plet
ra-di-ance
ra-di-cal
ra-di-cally
rain-ing
rambl-er
ram-bl-ing
ran-sack
ran-som
ra-ri-ty
rash-ly
ra-ttle-snake
re-bound
re-cede
re-cluse
re-cu-pe-ra-tion
re-cur
re-fine-ment
re-gi-ment
re-gu-la-ri-ty
re-mind-er
re-mi-ni-scence
re-mon-strate
ren-dez-vous
re-pair-per-son
re-pel
re-pe-ti-tive
re-pri-mand
re-puls-ive
re-pu-ta-ble
re-qui-site
re-sent-ful
re-source-ful
re-trace
re-veal-er
re-vul-sion
ri-cke-ty
ro-bot-arm
ro-bust
ru-dder
rude-ly
rug-ged
sa-bre-toothed
safe-guard
safe-keep-ing
sa-ga
sal-mo-ne-lla
sa-lon
sal-vage
san-guine
sar-cas-tica-lly
sar-dine
sa-ti-a-tion
sau-er-kraut
sa-va-nnah
scan-ty
scorn-ful-ly
scou-r
scur-ry
sea-shore
se-cre-cy
se-di-ment
se-du-lous-ly
seis-mo-me-ter
self-re-spect-ing
sen-sa-tion
sens-or
sen-ti-men-tal-ly
se-re-ni-ty
shad-y
shat-ter
shel-tered
shin-ing
shi-ver-ing
si-li-con
sil-ver-ware
sin-ce-ri-ty
si-re
ske-le-ton
ski-er
skir-mish
slan-der
slaugh-ter
sli-ppers
slum-ber
smug-gler
snob-be-ry
snow-ing
so-ci-o-lo-gist
sole-ly
so-li-ta-ry
so-li-tude
so-phis-ti-ca-tion
sort-ing
sound-ing
spa-cious
spa-sm
spe-ci-men
spe-cu-la-tion
spe-cu-la-tive
speed-boat
spir-al
spi-re
spite-ful
squa-dron
stag-ger-ing
sta-lac-tite
sta-lag-mite
star-board
steam-ship
steep-en
ste-reo-type
ste-ril-ize
store-room
stout-ly
stra-ta
strong-mind-ed
strych-nine
stuff-y
sub-due
sub-miss-ive
sub-ser-vient
su-ffice
sunk-en
su-per-in-tend-ent
su-per-struc-ture
su-per-vi-sor
su-scep-ti-ble
su-spi-cious
sus-te-nance
table-land
tank-er
ta-riff
tea-spoon-ful
tem-po
te-nant
ter-mite
te-rres-trial
te-ther
thirs-ti-ly
thi-ther
thrift-y
tick-lish
tip-ster
to-po-gra-phy
torch-light
tor-pe-do
to-rrent
tox-ic
tra-gic
trail-er
trans-verse
tra-vel-ing
tre-mor
trifl-ing
twit-ter
two-fold
un-ac-cep-ta-ble
un-ca-nny
un-crumpled
un-de-clared
un-de-ni-a-ble
un-der-clothes
un-der-cur-rent
un-der-es-ti-mate
un-der-side
un-der-tak-ing
un-do-ing
un-due
un-du-late
un-du-ly
un-fore-seen
un-hurt
u-nique-ly
un-rea-son-ing
un-re-lent-ing
un-screw
un-set-tle
un-shak-able
un-smil-ing
un-sym-pa-the-tic
un-told
un-u-tte-ra-ble
u-ti-li-ta-rian
va-liant
va-nished
va-riant
va-ry-ing
ven-til-ate
ven-ti-la-tion
ve-ri-fy
ve-ri-ta-ble
ver-na-cu-lar
ver-sus
ver-te-brate
ver-ti-cal-ly
vi-bra-tion
vi-car
vi-ci-ni-ty
vi-cious
vio-lent-ly
vi-per
vi-pe-rine
vi-sual-ize
vi-ta-li-ty
vi-ta-mins
vi-vi-fy
vul-gar
wan-der-ing
watch-dog
wa-ter-logged
wa-ter-spout
wheel-ba-rrow
whim-si-cal
whis-ky
wi-cked-ly
win-dow-sill
wind-screen
work-sta-tion
worth-less
yawn-ing
zoo-morph-ic
ae-ro-plane
fa-vo-rite
Fi-nish
hair-dress-er
sta-tion-er
