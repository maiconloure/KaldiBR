#!/bin/bash
#
# Cassio Batista   - https://cassota.gitlab.io/
# Ana Larissa Dias - larissa.engcomp@gmail.com

TAG="GMM"
COLOR_B="\e[93m"
COLOR_E="\e[0m"

function usage() {
    echo "usage: (bash) $0 OPTIONS"
    echo "eg.: $0 --nj 2 --num_leaves 500 --tot_gauss 1000 --lm_order 2"
    echo ""
    echo "OPTIONS"
    echo "  --nj            number of parallel jobs "
    echo "  --num_leaves    number of states in the decision tree "
    echo "  --tot_gauss     total number of gaussians"
    echo "  --lm_order      language model order (n-gram quantity)"
}

if test $# -eq 0 ; then
    usage
    exit 1
fi

while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        --nj)
            nj="$2"
            shift # past argument
            shift # past value
        ;;
        --num_leaves)
            num_leaves="$2"
            shift # past argument
            shift # past value
        ;;
        --tot_gauss)
            tot_gauss="$2"
            shift # past argument
            shift # past value
        ;;
        --lm_order)
            lm_order="$2"
            shift # past argument
            shift # past value
        ;;
        *)  # unknown option
            echo "[$TAG] unknown flag $1"
            usage
            shift # past argument
            exit 0
        ;;
    esac
done

if [[ -z $nj || -z $num_leaves  || -z $tot_gauss || -z $lm_order ]] ; then
    echo "[$TAG] a problem with the arg flags has been detected"
    usage
    exit 1
fi

echo -e $COLOR_B
echo "===== [$TAG] PREPARING ACOUSTIC DATA ====="
echo -e $COLOR_E

# Needs to be prepared by hand for each train and test data (or using self written scripts):
#
# corpus.txt  [<text_transcription>]
# spk2gender  [<speaker-id> <gender>]
# text        [<uterranceID> <text_transcription>]
# utt2spk     [<uterranceID> <speakerID>]
# wav.scp     [<uterranceID> <full_path_to_audio_file>]

# Making spk2utt files
utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
utils/utt2spk_to_spk2utt.pl data/test/utt2spk  > data/test/spk2utt

# Making feats.scp files
mfccdir=mfcc

echo -e $COLOR_B
echo "[$TAG] VALIDATING AND FIXING DIRS ====="
echo -e $COLOR_E

utils/validate_data_dir.sh  data/train # script for checking prepared data 
utils/fix_data_dir.sh       data/train # tool for data proper sorting if needed 
utils/validate_data_dir.sh  data/test  # script for checking prepared data 
utils/fix_data_dir.sh       data/test  # tool for data proper sorting if needed 

echo -e $COLOR_B
echo "[$TAG] FEATURES EXTRACTION ====="
echo -e $COLOR_E

steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir
steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/test  exp/make_mfcc/test  $mfccdir

# Making cmvn.scp files
steps/compute_cmvn_stats.sh data/train exp/make_mfcc/train $mfccdir
steps/compute_cmvn_stats.sh data/test  exp/make_mfcc/test  $mfccdir

echo -e $COLOR_B
echo "===== [$TAG] PREPARING LANGUAGE DATA ====="
echo -e $COLOR_E

# Needs to be prepared by hand (or using self written scripts):
#
# lexicon.txt           [<word> <phone 1> <phone 2> ...]
# optional_silence.txt  [<phone>]
# nonsilence_phones.txt [<phone>]
# silence_phones.txt    [<phone>]

# Preparing language data
utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

echo -e $COLOR_B
echo "[$TAG] LANGUAGE MODEL CREATION ====="
#echo "===== MAKING lm.arpa ====="
echo -e $COLOR_E

#loc=`which ngram-count`;
#if [ -z $loc ]; then
#	if uname -a | grep 64 >/dev/null; then
#		sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
#	else		sdir=$KALDI_ROOT/tools/srilm/bin/i686
#	fi
#	if [ -f $sdir/ngram-count ]; then
#		echo "Using SRILM language modelling tool from $sdir"
#		export PATH=$PATH:$sdir
#	else
#		echo "SRILM toolkit is probably not installed.
#				Instructions: tools/install_srilm.sh"
#		exit 1
#  fi
#fi
# Example of how to train your own language model. Note: It is not recommended to train your language model using the same dataset that will be used for the  acoustic model training.
#cat data/train/corpus.txt data/test/corpus.txt > data/local/corpus.txt
#local=data/local
#ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa

local=data/local
if [ ! -d "$local/tmp" ]; then
    echo -e $COLOR_B
    echo "[$TAG] DOWNLOADING lm.arpa ====="
    echo -e $COLOR_E
    mkdir $local/tmp
    wget https://gitlab.com/fb-asr/fb-asr-resources/kaldi-resources/raw/master/lm/lm.arpa -P $local/tmp
else
    echo "[$TAG] lm.arpa already exists under $local/tmp"
fi

echo -e $COLOR_B
echo "[$TAG] CONVERTING lm.arpa to  G.fst ====="
echo -e $COLOR_E
lang=data/lang
arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang/words.txt $local/tmp/lm.arpa $lang/G.fst

echo -e $COLOR_B
echo "============== [$TAG] STARTING RUNNING GMM =============="
echo -e $COLOR_E

echo -e $COLOR_B
echo "[$TAG] MONO TRAINING ====="
echo -e $COLOR_E
steps/train_mono.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono  || exit 1

echo -e $COLOR_B
echo "[$TAG] MONO ALIGMENT ====="
echo -e $COLOR_E
steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali || exit 1

echo -e $COLOR_B
echo "[$TAG] TRIPHONE 1 TRAINING ====="
echo -e $COLOR_E
steps/train_deltas.sh --cmd "$train_cmd" $num_leaves $tot_gauss data/train data/lang exp/mono_ali exp/tri1 || exit 1

echo -e $COLOR_B
echo "[$TAG] TRIPHONE 1 ALIGNMENT ====="
echo -e $COLOR_E
steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali

echo -e $COLOR_B
echo "[$TAG] TRIPHONE 2 (Δ+ΔΔ) TRAINING ====="
echo -e $COLOR_E
steps/train_deltas.sh --cmd "$train_cmd" $num_leaves $tot_gauss data/train data/lang exp/tri1_ali exp/tri2|| exit 1  

echo -e $COLOR_B
echo "[$TAG] TRIPHONE 2 (Δ+ΔΔ) ALIGMENT ====="
echo -e $COLOR_E
steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri2 exp/tri2_ali

echo -e $COLOR_B
echo "[$TAG] TRIPHONE 3 (LDA+MLLT) TRAINING ====="
echo -e $COLOR_E
steps/train_lda_mllt.sh --cmd "$train_cmd" $num_leaves $tot_gauss data/train data/lang exp/tri2_ali exp/tri3 || exit 1

echo -e $COLOR_B
echo "[$TAG] TRIPHONE 3 (LDA-MLLT with fMLLR) ALIGNMENT ====="
echo -e $COLOR_E
steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri3 exp/tri3_ali

echo -e $COLOR_B
echo "[$TAG] TRIPHONE 3b (LDA+MLLT+SAT) TRAINING ====="
echo -e $COLOR_E
steps/train_sat.sh --cmd "$train_cmd" $num_leaves $tot_gauss data/train data/lang exp/tri3_ali exp/tri3b || exit 1

echo -e $COLOR_B
echo "[$TAG] TRIPHONE 3 (LDA-MLLT+SAT with fMLLR) ALIGNMENT ====="
echo -e $COLOR_E
steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri3b exp/tri3b_ali

echo -e $COLOR_B
echo "============== [$TAG] FINISHED RUNNING GMM =============="
echo -e $COLOR_E
