#include <stdio.h>
#include <memory.h>

#include "common.h"

size_t read_dmatrix(dvarray* out, const char* filename);
void dec_viterbi_F(dvector* Metr_mem, unsigned char* history_mem, bitvector* bit_stream,
                   const dvarray* Dist, const param_viterbi_t* param, size_t n);
void init_viterbi(param_viterbi_t* param, coderate_tt in_rate);

int main(void) 
{
  dvarray Dist_demux;
  param_viterbi_t param_viterbi;
  dvector Metr_mem;
  unsigned char* history_mem;
  bitvector d_bit_stream;

  dvarray_init(&Dist_demux, 0, 0);
  bitvector_init(&d_bit_stream, 0);

  init_viterbi(&param_viterbi, CODERATE_1D2);
  history_mem = (unsigned char*)malloc(sizeof(param_viterbi.history));
  memcpy(history_mem, param_viterbi.history, sizeof(param_viterbi.history));
  dvector_init(&Metr_mem, MAX_Nways);
  memcpy(Metr_mem.data, param_viterbi.Metr, sizeof(param_viterbi.Metr));

  read_dmatrix(&Dist_demux, "Dist_demux");

  printf("Starting Viterbi\n");
  dec_viterbi_F(&Metr_mem, history_mem, &d_bit_stream, &Dist_demux, &param_viterbi, 0);
  printf("\nViterbi finished\n");

  dvector_clear(&Metr_mem);
  dvarray_clear(&Dist_demux);
  bitvector_clear(&d_bit_stream);
  free(history_mem);

  return 0;
}
