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
    struct pstat *pstat = malloc(sizeof(struct pstat));
    int jcount = 0;

    while ( jcount < jobcount ) {
        int pid = fork2(2);
        if (pid < 0) {
            exit();
        } else if (pid == 0) {
            exec(job, ptr);
        } else if (pid > 0) {
            // getpinfo(pstat);
        }
        jcount++;
    }

    for (int i = 0; i < iterations; i++){
        getpinfo(pstat);
        for(int j = 0; j < NPROC; j++) {
            if (pstat->priority[j] == 2) {
                setpri(pstat->pid[j], 3);
            }
        }

        sleep(timeslice);
    }

    getpinfo(pstat);
    for (int i = 0; i < NPROC; i++) {
        if (pstat->state[i] == ZOMBIE) {
            //printf(1, "%s\n", "entered");
            wait();
            kill(pstat->pid[i]);
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