#include <stdio.h>
#include <math.h>

int main()
{
    // perform m * r
    int64_t m = -150;
    int64_t r = -32;
    int64_t radix_mask = 0x0000007;
    int64_t length_r = 28;

    r = r & 0xFFFFFFF;

    int64_t A = m << (length_r + 1);
    int64_t S = -A;
    int64_t P = r << 1;
    int64_t pos_twoA = (2*A);
    int64_t neg_twoA = (2*S);


    for (int i = 0; i < length_r/2; i++)
    {
        // look at last 2 bits
        int last_two_bits = P & radix_mask;
        switch (last_two_bits)
        {       
            case 1:
                P += A;
                break;

            case 2:
                P += A;
                break;

            case 3:
                P += pos_twoA;
                break;

            case 4:
                P += neg_twoA;
                break;

            case 5:
                P += S;
                break;

            case 6:
                P += S;
                break;

            default:
                // cases 0 & 3 (00 & 11)
                // Do nothing
                break;
        }
        P = P >> 2;
    }

    P = P >> 1;

    printf("\n\nThe result of %lld * %lld = %lld\n\n", (long long)m, (long long)r, (long long)P);

    return 0;
}