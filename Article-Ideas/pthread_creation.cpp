// pthread_creation.cpp

#include <pthread.h>
#include <iostream>
#include <cstdlib>	// provides exit()
#include <sched.h>	// provides sched_getcpu().  Linux specific.
using namespace std;

const int NUMBER_OF_THREADS = 5;

void *start_thread_routine( void * );

int main()
{
	pthread_t threads[NUMBER_OF_THREADS];
	for(long i=0 ; i< NUMBER_OF_THREADS ; i++ )
	{
		cout << "creating thread # " << i << '\n';
		int success = pthread_create( &threads[i] , NULL , start_thread_routine , (void *)i );
		if( success == -1 )
		{
			cout << "error: success == -1\n";
			exit( EXIT_FAILURE );
		}
	}
	pthread_exit( NULL );	// block until all created threads have returned or exited
}

void *start_thread_routine( void *id_integer )
{
	long id;
	id = (long) id_integer;
	cout << "\tThread " << id << " starting...\n";
	int core = sched_getcpu( );	// Linux specific.
	if( core != -1 )
		cout << "\tThread " << id << " is running on core " << core << endl;

	for(int i=0; i<100000000; i++); // do some work
	cout << "\texiting thread " << id << '\n';
	pthread_exit( NULL );
}
