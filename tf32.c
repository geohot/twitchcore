// https://blogs.nvidia.com/blog/2020/05/14/tensorfloat-32-precision-format/
// https://github.com/pulp-platform/fpnew
// Sign(1), Exponent(8), Mantissa (23 in FP32, 10 in TF32)

#include <stdio.h>
#include <stdint.h>

#define S(a) (a>>31)
#define E(a) ((a>>23)&((1<<8) - 1))
#define M(a) (a&((1<<23) - 1))

void fp(int a) {
  printf("    Sign: %d\n", S(a));
  printf("Exponent: %d\n", E(a));
  printf("Mantissa: %x\n", M(a));
}

int main() {
  float a = 1.3;
  float b = 4.5;
  float c = a*b;
  int fa = *(uint32_t*)(&a);
  int fb = *(uint32_t*)(&b);
  int fc = *(uint32_t*)(&c);
  printf("%f * %f = %f\n", a, b, c);
  printf("%x * %x = %x\n", fa, fb, fc);
  fp(fa);
  fp(fb);
  fp(fc);

  int ns = S(fa) * S(fb);
  int ne = (E(fa) + E(fb)) - 127;
  int nm = ((uint64_t)((1<<23)|M(fa)) * (uint64_t)((1<<23)|M(fb))) >> 23;
  int fct = (ns<<31) | ((ne&((1<<8) - 1)) << 23) | (nm&((1<<23) - 1));
  fp(fct);
  printf("%x %f\n", fct, *((float*)&fct));
}

