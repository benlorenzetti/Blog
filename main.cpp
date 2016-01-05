// test.cpp

#include <iostream>
#include <string>
#include <vector>
#include <cstdio>
#include <fstream>
#include "ipv6_socket_server.h"
#include "http.h"
#include "element.h"
#include "some_devices_using_libusb_and_pthreads.h"

using namespace std;

const int HTTP_REQUEST_SIZE = 100000;

const size_t BUFFER_SIZE = 100000;
char buffer[BUFFER_SIZE];

const int USB_RECIEVE_BUFFER_SIZE = 10000;

const int URI_LIST_SIZE = 5;
const char URI_LIST[URI_LIST_SIZE][SIZE_OF_EACH_URI] = {"\0"    , "abort" , "bio-micro-systems-banner.jpg", "connection-indicator.gif", "test-parameters"};
enum resource_types {DYN_HTML, STATIC_FILE};
const resource_types RESOURCE_TYPE  [URI_LIST_SIZE]  = {DYN_HTML, DYN_HTML, STATIC_FILE                   , STATIC_FILE               , DYN_HTML};

enum process_states {OPENING_EMSTAT, CLAIMING_EMSTAT, LAUNCHING_EVENT_HANDLER, OPENING_NEW_FILES, GETTING_TEST_PARAMETERS, USER_INPUT, READY_TO_START, CLOSING_FILES, ABORT_TEST};

int main()
{
	process_states global_state = OPENING_EMSTAT;

	ipv6_socket_server local_tcpip_server(HTTP, 1);
	emstat dev1;

	char socket_1_request[HTTP_REQUEST_SIZE];
	int socket_1_request_size;
	int socket_1_fd = -1;
	int process_state = 0;

	for (;;)
	{
		// Step 1: if no open HTTP request, accept a new HTTP request
		if (socket_1_fd == NO_CONNECTION_ACCEPTED)
		{
			memset(socket_1_request, 0, HTTP_REQUEST_SIZE);
			char client_ip_address[1000];
			socket_1_fd = local_tcpip_server.accept_connection(client_ip_address);
			if (socket_1_fd != NO_CONNECTION_ACCEPTED) {
				socket_1_request_size = 0;
				cout << "accepted TCP/IP connection from " << client_ip_address << endl;
			}
		}


		// Step 2: complete any open HTTP requests
		if (socket_1_fd != NO_CONNECTION_ACCEPTED)
		{
			// Step 2a: read additional data from the connection
			ssize_t recv_size = recv(socket_1_fd, socket_1_request + socket_1_request_size, (HTTP_REQUEST_SIZE - socket_1_request_size), 0);
			if (recv_size == -1 && errno == EBADF) { // if client closed connection
				cout << "recv() EBADF error (client closed connection)\n";
				local_tcpip_server.close_wrapper(socket_1_fd);
				socket_1_fd = NO_CONNECTION_ACCEPTED;
				continue;
			}
			else if (recv_size == -1) {
				cout << "recv() error: " << strerror(errno) << endl;
				cout << "closing TCP/IP connection." << endl;
				local_tcpip_server.close_wrapper(socket_1_fd);
				socket_1_fd = NO_CONNECTION_ACCEPTED;
				continue;
			}
			else {
				cout << "recieved " << socket_1_request_size << "from client\n";
				socket_1_request_size += recv_size;
				socket_1_request[socket_1_request_size] = '\0';
				cout << "Current Request:\n" << socket_1_request << endl;
			}

			// Step 2b: parse http request
			const char HOST_NAME[] = "localhost";
			unsigned long int parser_state;
			char *req_resource, *req_query, *fragment;
			int req_status_code = parse_http_request_line(socket_1_request, parser_state, HOST_NAME, req_resource, req_query, fragment);
			if (req_status_code == HTTP_BAD_REQUEST || req_status_code == DOES_NOT_MATCH_HOST) {
				cout << "parse_http_request_line () returned HTTP_BAD_REQUEST\n";
				string error_msg;
				local_tcpip_server.send_wrapper(socket_1_fd, "HTTP/1.1 400 Bad Request (Request-Line)\r\n", error_msg);
				local_tcpip_server.close_wrapper(socket_1_fd);
				socket_1_fd = NO_CONNECTION_ACCEPTED;
				continue;
			}
			else if (req_status_code == HTTP_NOT_IMPLEMENTED) {
				cout << "parse_http_request_line () returned HTTP_NOT_IMPLEMENTED\n";
				string error_msg;
				local_tcpip_server.send_wrapper(socket_1_fd, "HTTP/1.1 501 Not Implemented (bad method?)\r\n", error_msg);
				local_tcpip_server.close_wrapper(socket_1_fd);
				socket_1_fd = NO_CONNECTION_ACCEPTED;
				continue;
			}

			// Step 2c: identify the user's request
			int resource_index = resource_name_search(req_resource, URI_LIST[0], URI_LIST_SIZE);
			if (resource_index == -1)
			{
				string response_message("HTTP/1.1 204 No Content\r\n");
				cout << "Sending the following message:\n" << response_message << endl;
				string temp_string;
				local_tcpip_server.send_wrapper(socket_1_fd, response_message, temp_string);
				local_tcpip_server.close_wrapper(socket_1_fd);
				socket_1_fd = NO_CONNECTION_ACCEPTED;
				continue;
			}
			cout << "requested resource \"" << req_resource << "\" has index " << resource_index << endl;
			
			// Step 2d: deal with user input
			if (resource_index == 1) // "abort"
			{
				cout << "User issued abort.\n";
				global_state = ABORT_TEST;
			}
			

			// Step 2e: generate content, if necessary
			string dynamic_resource;
			if (RESOURCE_TYPE[resource_index] == DYN_HTML) {
				element e0;
				element e1(0, HTML, LANG, "en");
				element e2(1, HEAD);
				element e3(2, META, CHARSET, "UTF - 8");
				element e4(2, TITLE, "Manganese Measurement Point of Care System");
				element e5(2, STYLE, "body {background-color:lightgrey; margin: 0; padding: 0; border: 0;}");
				e5.add_plain_text_content("header {min-height:35px; background-color: black;}");
				e5.add_plain_text_content("#centered {width: 960px; margin-left: auto; margin-right: auto; background-color: white;}");
				e5.add_plain_text_content("article {padding-left: 25px; padding-right: 10px;}");
				e5.add_plain_text_content("img {display: block; margin-left: auto; margin-right: auto;}");
				e5.add_plain_text_content(".next-button {margin-left: 600px; margin-top: 10px; margin-bottom: 10px;}");
				e5.add_plain_text_content("#connected-indicator {float: right;}");
				element e6(1, BODY);
				element e7(6, HEADER);
				element e8(6, DIV, ID, "centered");
				element e9(8, IMG, SRC, "bio-micro-systems-banner.jpg");
				e9.add_attribute(ALT, "BioMicroSystems Banner");
				element e10(8, ARTICLE);
				vector <element> elements;
				if (global_state == OPENING_EMSTAT && resource_index == 0) // homepage
				{ 
					elements.push_back(element(10, H1, "Manganese Measurement Sensor"));
					elements.push_back(element(10, P, "Welcome to the point-of-care measurement system for manganese exposure. To begin, ensure the EmStat is connected by USB."));
					elements.push_back(element(10, FORM, ACTION, "test-parameters", "<input class=\"next-button\" type=\"submit\" value=\"Connect\">"));
				}
				else if (global_state == OPENING_EMSTAT && resource_index == 4) // "test-parameters"
				{
					elements.push_back(element(10, H1, "usb error: unable to find EmStat device"));
					elements.push_back(element(10, P, "Please double check that EmStat is plugged into your PC, or try a different USB port."));
					elements.push_back(element(10, FORM, ACTION, "test-parameters", "<input class=\"next-button\" type=\"submit\" value=\"Test Connection\">"));
				}
				else if (global_state == CLAIMING_EMSTAT && resource_index == 4) // "test_parameters"
				{
					elements.push_back(element(10, H1, "usb error: unable to claim EmStat from OS"));
					elements.push_back(element(10, P, libusb_error_name (dev1.claim_interface(0))));
					elements.push_back(element(10, FORM, ACTION, "test-parameters", "<input class=\"next-button\" type=\"submit\" value=\"Test Connection\">"));

				}
				else if (global_state == GETTING_TEST_PARAMETERS && (resource_index == 0 || resource_index == 4)) // homepage or "test-parameters"
				{
					elements.push_back(element(10, H1, "Edit Test Parameters"));
					elements.push_back(element(10, IMG, SRC, "connection-indicator.gif"));
					elements.back().add_attribute(ALT, "Emstat Connected Indicator");
					elements.back().add_attribute(ID, "connected-indicator.gif");					
				}
				else if (global_state == ABORT_TEST)
				{
					elements.push_back(element(10, H1, "Aborting test..."));
					elements.push_back(element(10, FORM, ACTION, "http://localhost/", "<input class=\"next-button\" type=\"submit\" value=\"Refresh\">"));
				}
				dynamic_resource.append(e0.get_html());
			}


			// Step 2f: send the resource and close the connection
			string response_message, temp_string;

			if (RESOURCE_TYPE[resource_index] == STATIC_FILE)
			{
				FILE *file_ptr = fopen(req_resource, "rb"); // rb for read, binary
				if (file_ptr == NULL) {
					cout << "Error: could not find file " << req_resource << "(type \"quit\" to exit)" << endl;
					cin >> temp_string;
					exit(EXIT_FAILURE);
				}
				else {
					while (!feof(file_ptr))
					{
						size_t file_size = fread ((void*)buffer, 1, BUFFER_SIZE, file_ptr);
						if (file_size == BUFFER_SIZE) {
							cout << "Error: file size exceeds the global buffer size (type quit to exit)\n";
							cin >> temp_string;
							exit (EXIT_FAILURE);
						}
						cout << "file " << req_resource << " was successfully read (size = " << file_size << ")\n";
						if (!feof(file_ptr)) {
							response_message.append("HTTP/1.1 500 Could not read requested file\r\n");
							cout << "Sending the following message:\n" << response_message << endl;
							local_tcpip_server.send_wrapper(socket_1_fd, response_message, temp_string);
						}
						else {
							char temp_buffer[3000];
							int temp_size = fill_with_response_headers(temp_buffer, 200, file_size, 86400);
							local_tcpip_server.send_wrapper(socket_1_fd, temp_buffer, temp_size);
							local_tcpip_server.send_wrapper(socket_1_fd, buffer, file_size);
						}
					}
					fclose(file_ptr);
				}

			}
			else if (RESOURCE_TYPE[resource_index] == DYN_HTML)
			{
				fill_with_response_headers(buffer, 201, dynamic_resource.size(), 1);
				response_message.append(buffer);
				response_message.append(dynamic_resource);
				cout << "Sending the following message:\n" << response_message << endl << endl;
				local_tcpip_server.send_wrapper(socket_1_fd, response_message, temp_string);
			}
			local_tcpip_server.close_wrapper(socket_1_fd);
			socket_1_fd = NO_CONNECTION_ACCEPTED;

		}

		// Step 3: control emstat device
		
		if (global_state == OPENING_EMSTAT)
		{
			int dev_found = dev1.open_device(1027, 53633);
			if (dev_found == 0) {
				cout << "\nEmStat connection established\n";
				global_state = CLAIMING_EMSTAT;
			}
		}
		else if (global_state == CLAIMING_EMSTAT)
		{
			if (0 == dev1.claim_interface(0)) {
				cout << "\nEmStat interface 0 claimed.\n";
				global_state = LAUNCHING_EVENT_HANDLER;
			}
		}
		else if (global_state == LAUNCHING_EVENT_HANDLER)
		{
			dev1.start_event_handler_thread(USB_RECIEVE_BUFFER_SIZE);
			cout << "\nEmStat event handler thread launched.\n";
			global_state = GETTING_TEST_PARAMETERS;
		}
		else if (global_state == ABORT_TEST)
		{
			dev1.stop_event_handler_thread();
			global_state = CLOSING_FILES;
		}

		// step 4: perform local file I/O

		

	} // end of for (;forever;) loop


	/*	char http_request[10000];
	unsigned long int state;
	const char HOST[100] = "www.w3.org";
	char *resource, *query, *fragment;

	char *progress;
	progress = parse_http_request_line(request, state, HOST, resource, query, fragment);
	cout << "state = ";
	for (int i = 31; i >= 0; i--) {
	if (0 == ((i + 1) % 4))
	cout << ' ';
	cout << ((((state >> i) % 2) == 1) ? "1" : "0");
	} cout << endl;
	if (resource != NULL)
	cout << "resource = " << resource << endl;
	if (query != NULL)
	cout << "query = " << query << endl;
	if (fragment != NULL)
	cout << "fragment = " << fragment << endl;
	cout << "remainder of request:\n" << progress << "\nend remainder of request" << endl;
	*/
}

