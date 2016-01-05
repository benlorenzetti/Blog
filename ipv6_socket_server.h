/*  ipv6_socket_server.h
*/

#ifndef IPV6_SOCKET_SERVER_H
#define IPV6_SOCKET_SERVER_H

// Required on both Windows and Unix Systems
#include <iostream>
#include <sys/types.h>
#include <cstdlib>
#include <cerrno> // int errno
#include <string.h> // strerror ()
#include <string>

// Required only on Windows Systems
#ifndef _Windows
#pragma warning(disable: 4996)
#pragma comment(lib, "Ws2_32.lib")
#include <WinSock2.h>
#include <Ws2tcpip.h>
#include <io.h>
#ifndef _SSIZE_T_DEFINED
#define _SSIZE_T_DEFINED
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;
#endif /* _SSIZE_T_DEFINED */
#define close closesocket

// Required only on Unix Systems
#else
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <unistd.h> // read(), write(), close()
#include <fcntl.h>
#endif

using namespace std;

enum ports { HTTP };
const int NO_CONNECTION_ACCEPTED = -1;

class ipv6_socket_server
{
public:
	ipv6_socket_server(ports, int);
	// Opens a socket(), bind()s it to the local machine, and listen()s for incoming IPv6 connections
	// @param: port type (choose from enumerated list above)
	// @param: maximum queue size for incoming connections
	int accept_connection(char *);
	// Accept()s an incoming connection
	// @param: filled with the connecting machine's IPv6 address
	// return: a socket file descriptor with an open connection, or NO_CONNECTION_ACCEPTED on error and sets errno
	static string recv_wrapper(int);
	// @param: socket file descriptor
	// return: string sent by the remote client, or an error msg
	static int send_wrapper(int, string, string &);
	// @param: socket file descriptor
	// @param: string to be sent
	// @param: return error message
	// return: size sent, or -1 on error
	static int send_wrapper(int, const char *, int);
	// @param: socket file descriptor
	// @param: data to send
	// @param: size of data array
	// return: total size sent
	static void close_wrapper(int);
	// @param: socket file descriptor to close
	/*
	* Note: all 3 of the wrapper functions [read_wrapper(), write_wrapper(), and close_wrapper()]
	*       could be replaced by direct calls to read(), write(), and close(), which are supplied
	*       by unistd.h (io.h on Windows).
	*/
	~ipv6_socket_server();
private:
	int sock_fd;
};

ipv6_socket_server::ipv6_socket_server(ports port, int max_queue_size)
{
	// Call WSAStartup if a Windows Machine (load the dll)
#ifndef _Windows
	WORD wVersionRequested;
	WSADATA wsaData;
	int wsaerr;

	// Using MAKEWORD macro, Winsock version request 2.2
	wVersionRequested = MAKEWORD(2, 2);

	wsaerr = WSAStartup(wVersionRequested, &wsaData);
	if (wsaerr != 0)
	{
		/* Tell the user that we could not find a usable */
		/* WinSock DLL.*/
		cout << "The Winsock dll not found!\n";
		exit(EXIT_FAILURE);
	}
#endif // _Windows

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
	char port_c_string[1000];
	switch (port)
	{
	case HTTP: strcpy(port_c_string, "80"); break;
	}

	// Call getaddrinfo () to query DNS and set up a socket address struct
	struct addrinfo *addrinfo_list;
	int success = getaddrinfo(NULL, port_c_string, &hints, &addrinfo_list);
	if (success != 0)
	{
		cout << "Error in getaddrinfo (): " << gai_strerror(success) << endl;
		//		exit(EXIT_FAILURE);
	}

	// Try each address in the list until one can be named
	struct addrinfo *i;
	for (i = addrinfo_list; i != NULL; i = i->ai_next)
	{
		// Get a socket file descriptor from the OS
		sock_fd = socket(i->ai_family, i->ai_socktype, i->ai_protocol);
		if (sock_fd == -1)
			continue;	// -1 is failure, continue to next iteration

		// Assign a name to the socket (bind to an address)
		success = bind(sock_fd, i->ai_addr, i->ai_addrlen);
		if (success == 0)
			break;	// 0 is successful bind. Use this file descriptor
		cout << "bind (): " << strerror(errno) << endl;

		// Close the socket file descriptor if unsuccessful
		close(sock_fd);
	}
	if (success != 0)
	{
		cout << "Error in ipv6_socket_server(): was unable to bind to an IPv6 Socket\n";
		cout << "(try running as super user)\n";
		exit(EXIT_FAILURE);
	}

	// Free the addrinfo_list from getaddrinfo ()
	freeaddrinfo(addrinfo_list);

	// Set the socket to be nonblocking
	#ifndef _Windows
		unsigned long on = 1;
		if (0 != ioctlsocket(sock_fd, FIONBIO, &on)) {
			cout << "ioctlsocket() error.\n";
			exit(EXIT_FAILURE);
		}
	#else
		if (!fcntl (sock_fd, F_SETFL, O_NONBLOCK)) {
			cout << "fcntl() error " << strerror(errno) << endl;
			exit(EXIT_FAILURE);
		}
	#endif

	// Indicate that the socket is passive, waiting for connections
	if (listen(sock_fd, max_queue_size) != 0)
	{
		cout << "listen(): " << strerror(errno) << endl;
		exit(EXIT_FAILURE);
	}
}

int ipv6_socket_server::accept_connection(char *ipv6_address)
{
	// Accept the connection and get a file descriptor
	sockaddr_in6 sock_addr;
	socklen_t size = sizeof(sock_addr);
	memset(&sock_addr, 0, sizeof(sock_addr));
	int connection_sfd = accept(sock_fd, (sockaddr *)&sock_addr, &size);
	if (connection_sfd != -1)
		inet_ntop(AF_INET6, (void *)&sock_addr, ipv6_address, size);
	return connection_sfd;
}

string ipv6_socket_server::recv_wrapper(int sfd)
{
	const int BUFFER_SIZE = 1000;
	char buffer[BUFFER_SIZE];
	ssize_t buffer_size = BUFFER_SIZE;
	string temp;
	/* Make repeating calls to read() until entire message is complete.
	* Read() returns number of characters filled; 0 indicates end of file.
	* Read() returns -1 for error and sets errno. */
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

void ipv6_socket_server::close_wrapper(int sfd)
{
	close(sfd);
}

ipv6_socket_server::~ipv6_socket_server()
{
	close(sock_fd);
}
#endif
