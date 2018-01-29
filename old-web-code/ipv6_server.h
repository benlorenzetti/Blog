/*  ipv6_server.h
*/

#ifndef IPV6_SERVER_H
#define IPV6_SERVER_H

#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h> // int errno
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <unistd.h> // read(), write(), close()
#include <fcntl.h>

#define HTTP_PORT	80
#define	NO_CONNECTION_ACCEPTED	-1

struct open_connection {
	struct open_connection* next_OC;
	int sock_fd;
	char ip_address[64];
};

struct ipv6_server {
	int sock_fd;
	struct open_connection* OC_list;	
};

int start_ipv6_server (struct ipv6_server*, int, int);
	// Opens a socket(), bind()s it to the local machine, and listen()s for incoming IPv6 connections
	// @param: a server "object"
	// @param: port type (an HTTP_PORT is 80)
	// @param: maximum queue size for incoming connections
	int accept_connection (struct ipv6_server*);
	// Accept()s an incoming connection
	// @param: the server "object"
	// return: a socket file descriptor with an open connection, or a NO_CONNECTION_ACCEPTED on error and sets errno
//	static string recv_wrapper(int);
	// @param: socket file descriptor
	// return: string sent by the remote client, or an error msg
//	static int send_wrapper(int, string, string &);
	// @param: socket file descriptor
	// @param: string to be sent
	// @param: return error message
	// return: size sent, or -1 on error
//	static int send_wrapper(int, const char *, int);
	// @param: socket file descriptor
	// @param: data to send
	// @param: size of data array
	// return: total size sent
//	void close_connection(struct ipv6_server*, int);
	// @param: the server "object"
	// @param: socket file descriptor to close
	/*
	* Note: all 3 of the wrapper functions [read_wrapper(), write_wrapper(), and close_wrapper()]
	*       could be replaced by direct calls to read(), write(), and close(), which are supplied
	*       by unistd.h (io.h on Windows).
	*/
	void stop_ipv6_server(struct ipv6_server*);

int start_ipv6_server (struct ipv6_server* server, int port, int max_queue_size)
{
	// Set up the hints parameter for getaddrinfo ()
	struct addrinfo hints;
	memset(&hints, 0, sizeof(hints));
	hints.ai_family = AF_INET6; // not AF_UNSPEC or AF_INET
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = 0;
	hints.ai_flags = AI_PASSIVE; // fills in the address for this machine
	hints.ai_canonname = NULL;
	hints.ai_addr = NULL;
	hints.ai_next = NULL;

	// Create the correct port string
	char port_c_string[8];
	switch (port)
	{
		case HTTP_PORT:
			strcpy(port_c_string, "80");
			break;
		default:
			printf ("start_ipv6_server(): port number %d not recognized.\n", port);
	}

	// Call getaddrinfo () to query DNS and set up a socket address struct
	struct addrinfo *addrinfo_list;
	int failure;
	failure = getaddrinfo(NULL, port_c_string, &hints, &addrinfo_list);
	if (failure != 0)
		printf ("start_ipv6_server(): getaddrinfo() error: %d\n", failure);
	
	// Try each address in the list until one can be named
	struct addrinfo *i;
	for (i = addrinfo_list; i != NULL; i = i->ai_next)
	{
		// Get a socket file descriptor from the OS
		server->sock_fd = socket(i->ai_family, i->ai_socktype, i->ai_protocol);
		if (server->sock_fd == -1)
			continue;	// -1 is failure, continue to next iteration

		// Assign a name to the socket (bind to an address)
		failure = bind(server->sock_fd, i->ai_addr, i->ai_addrlen);
		if (failure == 0) {
			printf ("start_ipv6_server(): bind successful, continuing...\n");
			break;	// 0 is successful bind. Use this file descriptor
		}

		printf ("start_ipv6_server(): unable to bind (%d)\n", failure);
		// Close the socket file descriptor if unsuccessful
		close(server->sock_fd);
	}
	if (failure != 0)
	{
		printf ("Error in ipv6_socket_server(): was unable to bind to an IPv6 Socket\n");
		printf ("(try running as super user)\n");
		exit(EXIT_FAILURE);
	}

	// Free the addrinfo_list from getaddrinfo ()
	freeaddrinfo(addrinfo_list);

	// Indicate that the socket is passive, waiting for connections
	if (0 != listen (server->sock_fd, max_queue_size))
	{
		printf ("listen(): %d\n", errno);
		exit(EXIT_FAILURE);
	}

	// Initialize other members of the ipv6_server* object
	server->OC_list = NULL;
}

int accept_connection (struct ipv6_server* server)
{
	// Accept the connection and get a file descriptor
	struct sockaddr_in6 sock_addr;
	socklen_t size = sizeof(sock_addr);
	memset(&sock_addr, 0, sizeof(sock_addr));
	int connection_sfd = accept(server->sock_fd, (struct sockaddr *)&sock_addr, &size);
	if (connection_sfd != -1) {
		// Append a new open connection to the linked list
		// 1. LOCK THE LIST IF MULTITHREADING

		// 2. Find the end of the list
		struct open_connection** addr_of_OC_ptr;
		addr_of_OC_ptr = &server->OC_list;
		while (*addr_of_OC_ptr != NULL) {
			printf ("linked list iteration\n");
			addr_of_OC_ptr = & ( (*addr_of_OC_ptr)->next_OC);
		}
		
		// 3. Append new Open Connection Object to the back of the list
		*addr_of_OC_ptr = malloc (sizeof (struct open_connection));
		if (*addr_of_OC_ptr == NULL) {
			printf ("Memory allocation failure for new open_connection struct.\n");
			close (connection_sfd);
		}

		// 4. Initialize Data Members of New Object
		(*addr_of_OC_ptr)->next_OC = 0;
		(*addr_of_OC_ptr)->sock_fd = connection_sfd;
		inet_ntop(AF_INET6, (void *)&sock_addr, (*addr_of_OC_ptr)->ip_address, size);

	}
	return connection_sfd;
}

/*
string ipv6_socket_server::recv_wrapper(int sfd)
{
	const int BUFFER_SIZE = 1000;
	char buffer[BUFFER_SIZE];
	ssize_t buffer_size = BUFFER_SIZE;
	string temp;
	// Make repeating calls to read() until entire message is complete.
	// Read() returns number of characters filled; 0 indicates end of file.
	//  Read() returns -1 for error and sets errno.
	while (buffer_size != 0)
	{
		// Read from the file descriptor
		buffer_size = read(sfd, (void *)buffer, BUFFER_SIZE);
		if (buffer_size == -1)
		{
			string error_msg = "read() error: ";
			error_msg.append(strerror(errno));
			return error_msg;
		}
		temp.append(buffer);
	}
	return temp;
}
*/


/*
int ipv6_socket_server::send_wrapper(int sfd, string to_send, string &error_message)
{
	int size_sent = 0;
	const int BUFFER_SIZE = 1000;
	char buffer[BUFFER_SIZE];
	while (to_send.size() > size_sent)
	{
		string not_sent = to_send.substr(size_sent, BUFFER_SIZE);
		strncpy(buffer, not_sent.c_str(), BUFFER_SIZE);
		int ret = send(sfd, buffer, not_sent.size(), 0);
		if (ret < 0)
		{
			error_message = "send() error: ";
			error_message.append(strerror(errno));
			return -1;
		}
		else
			size_sent += ret;
	}
	return size_sent;
}
*/

/*
int ipv6_socket_server::send_wrapper(int sfd, const char *to_send, int size)
{
	const int ALLOWED_ATTEMPTS = 10;
	int attempts = 0;
	int size_sent = 0;
	while (size_sent < size && attempts++ < ALLOWED_ATTEMPTS)
	{
		int ret = send(sfd, (to_send + size_sent), (size-size_sent), 0);
		if (ret < 0)
			break;
		else
			size_sent += ret;
	}
	return size_sent;
}
*/

/*
void close_connection (struct ipv6_server* server, int sfd)
{
	close(sfd);
}
*/

void stop_ipv6_server (struct ipv6_server* server)
{
	close(server->sock_fd);
}

#endif
