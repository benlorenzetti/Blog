/*	webserver.c
 *
 */

#include "ipv6_server.h"
#include <stdio.h>

main()
{
	printf ("starting program.\n");
	struct ipv6_server webserver;
	start_ipv6_server (&webserver, HTTP_PORT, 1);
	for (;;) {
		accept_connection (&webserver);
	}
	stop_ipv6_server (&webserver);
}
