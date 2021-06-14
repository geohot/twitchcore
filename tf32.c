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

int mul(int fa, int fb) {
  int ns = S(fa) ^ S(fb);
  int ne = (E(fa) + E(fb)) - 127;
  int nm = ((uint64_t)((1<<23)|M(fa)) * (uint64_t)((1<<23)|M(fb))) >> 23;
  return (ns<<31) | ((ne&((1<<8) - 1)) << 23) | (nm&((1<<23) - 1));
}

int add(int fa, int fb) {
  int me = (E(fa) > E(fb)) ? E(fa) : E(fb);

  // shift
  int ra = ((1<<23)|M(fa))>>(me-E(fa));
  int rb = ((1<<23)|M(fb))>>(me-E(fb));

  // fix signs
  ra *= (S(fa) ? -1 : 1);
  rb *= (S(fb) ? -1 : 1);

  // add the shifted
  int rc = ra+rb;
  int ns = rc<0;
  rc *= (ns ? -1 : 1);

  // normalize (are these the only possible?)
  switch (rc >> 23) {
    case 0:
      me -= 1; rc <<= 1;
      break;
    case 1:
      break;
    case 2:
    case 3:
      me += 1; rc >>= 1;
      break;
  }

  return (ns<<31) | ((me&((1<<8) - 1)) << 23) | (rc&((1<<23) - 1));
}

int main() {
  float a = 1.3;
  float b = -4.5;
  float c = a*b;
  float d = a+b;
  int fa = *(uint32_t*)(&a);
  int fb = *(uint32_t*)(&b);
  int fc = *(uint32_t*)(&c);
  int fd = *(uint32_t*)(&d);
  //printf("%f * %f = %f\n", a, b, c);
  printf("%f + %f = %f\n", a, b, d);
  fp(fa);
  fp(fb);
  //fp(fc);
  fp(fd);

  int tst = add(fa, fb);
  fp(tst);
  printf("%x %f\n", tst, *((float*)&tst));
}

