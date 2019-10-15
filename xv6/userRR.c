//
// Created by nikolas on 10/14/19.
//

#include "types.h"
#include "user.h"

void roundRobin(int timeslice, int iterations, char *job, int jobcount){

    for (int i = 0; i < iterations; i++){
        for (int j = 0; j < jobcount; j++){

        }

        char **ptr = &job;

        int pid = fork();
        if (pid < 0){
            exit();
        } else if (pid == 0){
            exec(job, ptr);
        } else if (pid > 0){

        }
    }

}


int main(int argc, char *argv[]) {
    if(argc != 5) {
        // TODO: print error message
        exit();
    }

    int timeslice = atoi(argv[1]);
    int iterations = atoi(argv[2]);
    char *job = malloc(sizeof(char) * (strlen(argv[3]) + 1));
    strcpy(job, argv[3]);
    int jobcount = atoi(argv[4]);

    roundRobin(timeslice, iterations, job, jobcount);
    free(job);
    exit();
}