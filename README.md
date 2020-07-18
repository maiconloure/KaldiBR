# FalaBrasil scripts for Kaldi

## Model training
See [`train/`](./train) dir.
```bash
$ ./prep_train.sh /path/to/kaldi/egs/myproject
$ cd /path/to/kaldi/egs/myproject/s5/
$ ./run.sh
```

## Diarization
See [`diarization/`](./diarization) dir.
```bash
$ ./prep_dia.sh /path/to/kaldi/egs/myproject
$ cd /path/to/kaldi/egs/myproject/v1/
$ ./run.sh
```

## Online decoding
See [`online/`](./online) dir.


# Citation

If you use these codes or want to mention the paper referred above, please cite 
us as one of the following: 

> Batista, C., Dias, A.L., Sampaio Neto, N. (2018) Baseline Acoustic Models for
> Brazilian Portuguese Using Kaldi Tools. Proc. IberSPEECH 2018, 77-81, DOI:
> 10.21437/IberSPEECH.2018-17.

```bibtex
@inproceedings{Batista2018,
  author    = {Cassio Batista and Ana Larissa Dias and Nelson {Sampaio Neto}},
  title     = {{Baseline Acoustic Models for Brazilian Portuguese Using Kaldi Tools}},
  year      = {2018},
  booktitle = {Proc. IberSPEECH 2018},
  pages     = {77--81},
  doi       = {10.21437/IberSPEECH.2018-17},
  url       = {http://dx.doi.org/10.21437/IberSPEECH.2018-17}
}
```    

:warning: This paper uses the outdated nnet2 recipes, while this repo has been
updated to the chain models' recipe via nnet3 scripts. If you really want nnet2
scripts, you may find them on tag `nnet2`. Try running `git tag`.


[![FalaBrasil](doc/logo_fb_github_footer.png)](https://ufpafalabrasil.gitlab.io/ "Visite o site do Grupo FalaBrasil") [![UFPA](doc/logo_ufpa_github_footer.png)](https://portal.ufpa.br/ "Visite o site da UFPA")

__Grupo FalaBrasil (2020)__ - https://ufpafalabrasil.gitlab.io/      
__Universidade Federal do Pará (UFPA)__ - https://portal.ufpa.br/     
Cassio Batista - https://cassota.gitlab.io/    
