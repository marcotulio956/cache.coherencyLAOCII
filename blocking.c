#include <stdio.h>
#include <stdlib.h>
#include <time.h>

//C:\Users\ofzbo\Documents\CeFeT_Mg\CEFET\Semestre6\aocIII

/*
my L1 size is 4x32KB: 129792
an int in C is 4 bytes

iterations:
-all of the 3 mxs sizes, summed, results in just over my L1 size
    hence, n: mx column/row size = 105
    bc: 105^2 => 11.025 integers x 3 mxs => 33.075 integers x 4 bytes => 132.300 bytes
-every mtx is 2nx2n
    n: mx column/row size = 210
    then: 210^2 => 44.100 integers x 3 mxs => 132.300 integers x 4 bytes => 529.200 bytes
-every mtx is 3nx3n
    n: mx column/row size = 315
    then: 315^2 => 99.225 integers x 3 mxs => 297.675 integers x 4 bytes => 1.190.700 bytes

explanations:
-The number of capacity misses clearly depends on N and the size of the cache.
If it can hold all three N-by-N matrices, then all is well, provided there are no cache
conflicts. 
-If the cache can hold one N-by-N matrix and one row of N, then at least
the ith row of y and the array z may stay in the cache
-To ensure that the elements being accessed can fit in the cache, the original
code is changed to compute on a submatrix of size B by B. Two inner loops
now compute in steps of size B rather than the full length of x and z. B is called
the blocking factor

*/

typedef struct squareMatrix{
    int size;//quantity of col n rows
    int* data;//|data|=size^2
}squareMatrix;

double get_seconds() { /* routine to read time in seconds */
    __time64_t ltime;
    _time64(&ltime);
    return (double)ltime;
}

int matrix_mul_nonblocking(squareMatrix* ma, squareMatrix* mb, squareMatrix* mc){//O(n^3)
    for (int i = 0; i < ma->size; i++) {
        for (int j = 0; j < ma->size; j++) {
            int sum = 0;
            for (int k = 0; k < ma->size; k++) {
                int b = *(mb->data + i*mb->size + k);
                int c = *(mc->data + k*mc->size + j);
                sum = sum + b*c;
            }
            *(ma->data + i*ma->size + j) = sum;
        }
    }
    return 0;
}

int matrix_mul_blocking(squareMatrix* ma, squareMatrix* mb, squareMatrix* mc){//O(n^4) but exploting fast L1 access
    int b = 103; //blocking mtx is bxb, must fit in L1
    //b < (L1/(3mxs + 4bytesints))^0.5, 103^2 => 10.609 integers x 4 bytes x 3 mxs => 127.308 bytes, which is a tight fit in L1
    for(int I=0;I<ma->size;I+= b){
        for(int J=0;J<ma->size;J+= b){
            for(int i=0;i<ma->size;i++){
                for(int j = I; j<((I+b)>ma->size?ma->size:(I+b)); j++){
                    int sum = 0;//it just multiply integers
                    for(int k = J; k<((J+b)>ma->size?ma->size:(J+b)); k++){
                        int b = *(mb->data + i*mb->size + k);
                        int c = *(mc->data + k*mc->size + j);
                        sum += b*c;
                    }
                    *(ma->data + i*ma->size + j) = sum;
                }
            }
        }
    }
    return 0;
}

void matrix_populate(squareMatrix* ma){
    for(int i = 0; i < ma->size; i++){
        for(int j = 0; j < ma->size; j++){
            int n = (rand() % 9) + 1;
            *(ma->data + i*ma->size + j) = n;
            //printf("populating %d %d %d \n", i, j, n);

        }
    }
}

void matrix_reset(squareMatrix* ma){
    for(int i = 0; i < ma->size; i++){
        for(int j = 0; j < ma->size; j++){
            *(ma->data + i*ma->size + j) = 0;
        }
    }
}

void matrix_print(squareMatrix* ma){
    for(int i = 0; i < ma->size; i++){
        for(int j = 0; j < ma->size; j++){
            printf("%d ", *(ma->data + i*ma->size + j));
        }
        printf("\n");
    }
}

int main() {
    //int msize[] = {3, 4, 5};//testing multiplications
    squareMatrix m[3];

    double sec0, sec1, deltasec; /* timing variables */
    int howmanytimes = 3;
    double periodpermul;

    /*int initialsize = 105;
    int maxsize = 3 * initialsize;
    float increment = 1.5; // 50%
    int* msize = (int*)malloc(sizeof(int));
    int index = 0;
    do{
        msize[index] = initialsize;
        initialsize *= increment;
        index++;

        msize = (int*)realloc(msize, sizeof(int)*(index+1));
    }while(initialsize < maxsize);
    int ITE = index;*/
    //or just
    int msize[] = {500, 750, 1000, 1250, 2000, 2500, 3000};
    int ITE = 7;


    printf("%d\n", howmanytimes);

    printf("<CSV>");
    for(int i = 0; i < ITE; i++){  
        printf(", %d", msize[i]);
    }

    printf("\nNONBLOCKING\n");
    printf("<CSV>");
    for(int it = 0; it < ITE; it++){
        for(int i = 0; i < 3; i++){
            m[i].size = msize[it];
            m[i].data = (int*)malloc(sizeof(int)*msize[it]*msize[it]);
        }
        matrix_reset(&m[0]);
        matrix_populate(&m[1]);
        matrix_populate(&m[2]);

        // printf("\n\tMB\n");
        // matrix_print(&m[1]);
        // printf("\tMC\n");
        // matrix_print(&m[2]);

        sec0 = get_seconds();
        for(int i = 0; i < howmanytimes; i++){
            matrix_mul_nonblocking(&m[0],&m[1],&m[2]);
        }   
        sec1 = get_seconds();

        deltasec = sec1 - sec0;

        periodpermul = deltasec/(double)howmanytimes;

        // printf("\tMA\n");
        // matrix_print(&m[0]);
        printf("(%lf, %lf) ", deltasec, periodpermul);

        for(int i = 0; i < 3; i++){
            free(m[i].data);
        }
    }
    printf("\nBLOCKING\n");
    printf("<CSV>");
    for(int it = 0; it < ITE; it++){
        for(int i = 0; i < 3; i++){
            m[i].size = msize[it];
            m[i].data = (int*)malloc(sizeof(int)*msize[it]*msize[it]);
        }
        matrix_reset(&m[0]);
        matrix_populate(&m[1]);
        matrix_populate(&m[2]);

        // printf("\n\tMB\n");
        // matrix_print(&m[1]);
        // printf("\tMC\n");
        // matrix_print(&m[2]);

        sec0 = get_seconds();
        for(int i = 0; i < howmanytimes; i++){
            matrix_mul_blocking(&m[0],&m[1],&m[2]);
        }   
        sec1 = get_seconds();

        deltasec = sec1 - sec0;

        periodpermul = deltasec/(double)howmanytimes;

        // printf("\tMA\n");
        // matrix_print(&m[0]);
        printf("(%lf, %lf) ", deltasec, periodpermul);
    }
    return 0;
}
