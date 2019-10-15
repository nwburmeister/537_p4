//
// Created by nikolas on 10/14/19.
//
#include "user.h"

void roundRobin(int timeslice, int iterations, char *job, int jobcount){

}


void main(int argc, char *argv[]) {
    if(argc != 5) {
        // TODO: print error message
        exit();
    }

    int timeslice = argv[1];
    int iterations = argv[2];
    char *job = malloc(sizeof(char) * (strlen(argv[3]) + 1));
    strcpy(job, argv[3]);
    int jobcount = argv[4];


    roundRobin(timeslice, iterations, job, jobcount);
    free(job);

}