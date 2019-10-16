//
// Created by nikolas on 10/14/19.
//


#include "types.h"
#include "user.h"
#include "param.h"
#include "mmu.h"
#include "proc.h"
#include "pstat.h"

int status;

void roundRobin(int timeslice, int iterations, char *job, int jobcount){

  //  struct pstat *pstat;

    char **ptr = &job;
    printf(1, "%s\n", job);
    int pid = fork();
    //getpinfo(pstat);
    if (pid < 0){
        // TODO PRINT ERROR MESSAGE
        exit();
    } else if (pid == 0){
        printf(1, "%s\n", "Executing");
        exec(job, ptr);

    } else if (pid > 0){
        wait(&status);
    }
    printf(1, "%s\n", "Sleeping!");
    sleep(1000);
    for (int i = 0; i < jobcount; i++) {

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