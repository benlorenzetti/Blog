/*    http.h
*
*    A collection of functions for parsing and generating HTTP requests and responses.
*    There is no class/object organization because HTTP is stateless.
*/

#include <iostream>
#include <cstdlib>
#include "construction_time.h"
using namespace std;

const int HTTP_09_GET_REQUEST = 1;
const int HTTP_10_GET_REQUEST = 2;
const int HTTP_11_GET_REQUEST = 3;
const int DOES_NOT_MATCH_HOST = 4;
const int HTTP_BAD_REQUEST = 400;
const int HTTP_NOT_IMPLEMENTED = 501;

int parse_http_request_line(  // Return: one of the indicator constants declared above
	char *,                   // @param: http request
	unsigned long int &,      // @param: state variable -- see below
	const char *,             // @param: domain's hostname or  "[ip-literal]"
	char *&,                  // @param: returns ptr towards the canonical resource string (NULL if empty)
	char *&,                  // @param: returns ptr towards the query string (NULL if empty)
	char *&);                 // @param: returns ptr towards the fragment string (NULL if empty)

/*    The state variable corresponds to the state diagram titled "HTTP-Request-Line-Parser.pdf".
*    When the parsing function returns, the state variable and the return character describe the
*    reason and location. The state variable can be broken down into the following pieces:
*
*      Bit  [31]:    1 on success, 0 for failure/unparsed
*      Bits [30:24]: 7-bits indicate request method, HTTP-version, etc.
*                    000 0001 - HTTP/0.9 GET request
*                    000 0010 - HTTP/1.0 GET request
*                    000 0011 - HTTP/1.1 GET request
*      Bits [23:16]: 8-bits to identify the current state, within a particular method's parsing tree
*                    (each method has its own state diagram)
*      Bits [15:0]:  16-bits for counting or substates
*                    (usually the number of times a state has looped-back to itself.)
*/

int parse_remainder_of_http_request(  // Return: one of the indicator constants declared above
	char *,                           // @param: ptr to 2nd line of http request
	int &,                            // @param: returns with Transfer-Encoding value
	int &,                            // @param: returns lesser of Content-Length value or Entity-Body size
	char *&);                         // @praam: returns ptr towards "de-chunked" Entity-Body

const int SIZE_OF_EACH_URI = 256;

int resource_name_search (  // Return: index in uri_list matching the search_term, or -1 if not found.
	const char *,           // @param: search_term
	const char * ,          // @param: uri_list in alphabetical order (ASCII)
	                        //         const char URI_LIST[3][SIZE_OF_EACH_URI] = {"resource-a", "resource-b", "resource-c"};
	int);                   // @param: uri_list_size

const int MAXIMUM_CONTENT_LENGTH = 100000; // Must be a power of ten

int fill_with_response_headers(  // Return: size filled
	char *,                      // @param: destination to write HTTP-Header lines
	int,                         // @param: status code
	int,                         // @param: content length
	int);                        // @param: time until expiration (in seconds)

inline bool case_insensitive_comparison(char, char);

inline char decode_uri_pct_character(   // Return: decoded character from ASCII 0-255
	char *);                             // @param: pointer to the second hex character

int parse_http_request_line(
	char *req,
	unsigned long int &state,
	const char *host,
	char *&resource,
	char *&query,
	char *&fragment)
{
	// Declare Constants
	const char GET[8] = "ET ";
	const char SCHEME[8] = "ttp:/";

	// initialize all return parameters
	char *ptr = req;
	state = 0;
	resource = NULL;
	query = NULL;
	fragment = NULL;

	// implement state machine with transistions after each character
	for (; ptr < req + 9000; ptr++)
	{

		//		/*
		cout << "State = ";
		for (int i = 31; i >= 0; i--) {
			if (0 == ((i + 1) % 4))
				cout << ' ';
			cout << ((((state >> i) % 2) == 1) ? "1" : "0");
		} cout << " *ptr = " << *ptr << endl;
		//		*/

		switch (state >> 16)
		{
		case 0x0000: // Unparsed
			switch (*ptr)
			{
			case 'G': state = 0x01000000; break;
			default: return HTTP_NOT_IMPLEMENTED;
			}
			break;
		case 0x0100: // "GET" SP Method
			if (state == 0x01000003 && (*ptr == 'h' || *ptr == 'H'))
				state = 0x01010000;
			else if (state == 0x01000003 && *ptr == '/') {
				state = 0x01080000;
				resource = ptr;
			}
			else if (*ptr == GET[state & 0x0000ffff])
				state++;
			else
				return HTTP_NOT_IMPLEMENTED;
			break;
		case 0x0101: // "http:/" Scheme
			if (state == 0x01010005 && *ptr == '/')
				state = 0x01020000;
			else if (case_insensitive_comparison(*ptr, SCHEME[state & 0x0000ffff]))
				state++;
			else
				return HTTP_BAD_REQUEST;
			break;
		case 0x0102: // Start Authority
			if (case_insensitive_comparison(*ptr, host[state & 0x0000ffff]))
				state = 0x01030001;
			else if (*ptr == '[')
				state = 0x01070000;
			else if (*ptr == '%')
				state = 0x01040000;
			else
				return HTTP_BAD_REQUEST;
			break;
		case 0x0103: // Host Comparison
			if (case_insensitive_comparison(*ptr, host[state & 0x0000ffff]))
				state++;
			else if (*ptr == '%')
				state = 0x01040000 + (state & 0x0000ffff);
			else if (*ptr == ':' && host[state & 0x0000ffff] == '\0')
				state = 0x01060000;
			else if (*ptr == '/' && host[state & 0x0000ffff] == '\0') {
				state = 0x01080000;
				resource = ptr + 1;
			}
			else
				return DOES_NOT_MATCH_HOST;
			break;
		case 0x0104: // Host Comparison % Encoded
			state = 0x01050000 + (state & 0x0000ffff);
			break;
		case 0x0105: // Host Comparison % Encoded HEX 1
			if (decode_uri_pct_character(ptr) == host[state & 0x0000ffff])
				state = 0x01030001 + (state & 0x0000ffff);
			else
				return DOES_NOT_MATCH_HOST;
			break;
		case 0x0106: // ":80" Port
			if (*ptr == '8' && *(ptr + 1) == '0' && *(ptr + 2) == '/') {
				ptr += 2;
				state = 0x01080000;
				resource = ptr + 1;
			}
			else
				return HTTP_BAD_REQUEST;
			break;
		case 0x0107: // IP-literal
			if (*ptr == ']' && *(ptr + 1) == '/') {
				ptr++;
				state = 0x01080000;
				resource = ptr + 1;
			}
			else
				return HTTP_BAD_REQUEST;
			break;
		case 0x0108: // "/" Resource Path
			if (*ptr == '%')
				state = 0x01090000 + (state & 0x0000ffff);
			else if (*ptr == '\r') {
				if (*(ptr - 1) == '/')
					resource[(state & 0x0000ffff) - 1] = '\0';
				else
					resource[state & 0x0000ffff] = '\0';
				state = 0x01120000;
			}
			else if (*ptr == ' ') {
				if (*(ptr - 1) == '/' && (state & 0x0000ffff) > 0)
					*(resource + (state & 0x0000ffff) - 1) = '\0';
				else
					*(resource + (state & 0x0000ffff)) = '\0';
				state = 0x01110000;
			}
			else if (*ptr == '?') {
				if (*(ptr - 1) == '/')
					resource[(state & 0x0000ffff) - 1] = '\0';
				else
					resource[state & 0x0000ffff] = '\0';
				query = ptr;
				state = 0x010b0000;
			}
			else if (*ptr == '#') {
				if (*(ptr - 1) == '/')
					resource[(state & 0x0000ffff) - 1] = '\0';
				else
					resource[state & 0x0000ffff] = '\0';
				fragment = ptr;
				state = 0x010e0000;
			}
			else {
				if (*ptr >= 'A' && *ptr <= 'Z')
					resource[state & 0x0000ffff] = *ptr + 32; // 'a'-'A' = 32
				else
					resource[state & 0x0000ffff] = *ptr;
				state++;
			}
			break;
		case 0x0109: // Resource % Encoded
			state = 0x010a0000 + (state & 0x0000ffff);
			break;
		case 0x010a: // Resource % Encoded HEX 1
			*(resource + (state & 0x0000ffff)) = decode_uri_pct_character(ptr);
			if (resource[state & 0x0000ffff] >= 'A' && resource[state & 0x0000ffff] <= 'Z')
				resource[state & 0x0000ffff] += 32;
			state = 0x01080001 + (state & 0x0000ffff);
			break;
		case 0x010b: // Query
			if (*ptr == '%')
				state = 0x010c0000 + (state & 0x0000ffff);
			else if (*ptr == '#') {
				*(query + (state & 0x0000ffff)) = '\0';
				fragment = ptr;
				state = 0x010e0000;
			}
			else if (*ptr == ' ') {
				*(query + (state & 0x0000ffff)) = '\0';
				state = 0x01110000;
			}
			else if (*ptr == '\r') {
				*(query + (state & 0x0000ffff)) = '\0';
				state = 0x01120000;
			}
			else {
				*(query + (state & 0x0000ffff)) = *ptr;
				state++;
			}
			break;
		case 0x010c: // Query % Encoded
			state = 0x010d0000 + (state & 0x0000ffff);
			break;
		case 0x010d: // Query % Encoded HEX 1
			*(query + (state & 0x0000ffff)) = decode_uri_pct_character(ptr);
			state = 0x010b0001 + (state & 0x0000ffff);
			break;
		case 0x010e: // "#" Fragment
			if (*ptr == '%')
				state = 0x010f0000 + (state & 0x0000ffff);
			else if (*ptr == ' ') {
				*(fragment + (state & 0x0000ffff)) = '\0';
				state = 0x01110000;
			}
			else if (*ptr == '\r') {
				*(fragment + (state & 0x0000ffff)) = '\0';
				state = 0x01120000;
			}
			else {
				*(fragment + (state & 0x0000ffff)) = *ptr;
				state++;
			}
			break;
		case 0x010f: // Fragment % Encoded
			state = 0x01100000 + (state & 0x0000ffff);
			break;
		case 0x0110: // Fragment % Encoded HEX 1
			*(fragment + (state & 0x0000ffff)) = decode_uri_pct_character(ptr);
			state = 0x010e0001 + (state & 0x0000ffff);
			break;
		case 0x0111: // GET "HTTP/1.x" Version
			if (*ptr == 'H' && *(ptr + 1) == 'T' && *(ptr + 2) == 'T' && *(ptr + 3) == 'P' && *(ptr + 4) == '/' && *(ptr + 5) == '1' && *(ptr + 6) == '.' && *(ptr + 7) == '1' && *(ptr + 8) == '\r' && *(ptr + 9) == '\n') {
				state = 0x83000000 + (ptr-req) + 10; // 10 is HTTP/1.x\r\n length
				return HTTP_11_GET_REQUEST;
			}
			else if (*ptr == 'H' && *(ptr + 1) == 'T' && *(ptr + 2) == 'T' && *(ptr + 3) == 'P' && *(ptr + 4) == '/' && *(ptr + 5) == '1' && *(ptr + 6) == '.' && *(ptr + 7) == '0' && *(ptr + 8) == '\r' && *(ptr + 9) == '\n') {
				state = 0x82000000 + (ptr-req) + 10; // 10 = sizeof ("HTTP/1.x\r\n")
				return HTTP_10_GET_REQUEST;
			}
			else
				return HTTP_BAD_REQUEST;
			break;
		case 0x0112: // GET Version 0.9
			if (*ptr == '\n') {
				state = 0x81000000 + (ptr - req) + 1; // 1 = sizeof ("\n")
				return HTTP_09_GET_REQUEST;
			}
			else
				return HTTP_BAD_REQUEST;
			break;
		default:
			return HTTP_BAD_REQUEST;
		}
	}

	// warning: this point should never be reached!
	cout << "Warning: this point should never be reached! (leaky state machine).\n";
	exit(EXIT_FAILURE);
}

int parse_remainder_of_http_request(char *req, int &trans_encoding, int &content_length, char *&entity_body)
{

	return 500;
}

int resource_name_search (const char *search_term, const char *uri_list, int uri_list_size)
{
	const char *list = uri_list;
	unsigned int list_size = uri_list_size;
	unsigned int binary_offset = 1 << 14;
	while (binary_offset > 0)
	{
		cout << "list = " << (list - uri_list) << ", size = " << list_size << ", binary_offset = " << binary_offset << endl;
		if (binary_offset >= list_size) {
			binary_offset /= 2;
		}
		else if (strcmp(search_term, list+binary_offset*SIZE_OF_EACH_URI) < 0) {
			cout << "strcmp(" << search_term << ", " << (list+binary_offset*SIZE_OF_EACH_URI) << ") returns ";
			cout << strcmp(search_term, list+binary_offset*SIZE_OF_EACH_URI) << endl;
			list_size = binary_offset;
		}
		else {
			cout << "strcmp(" << search_term << ", " << (list+binary_offset*SIZE_OF_EACH_URI) << ") returns ";
			cout << strcmp(search_term, list+binary_offset*SIZE_OF_EACH_URI) << endl;
			list += binary_offset * SIZE_OF_EACH_URI;
			list_size -= binary_offset;
		}
	}
	if (!strcmp(search_term, list))
		return (list - uri_list) / SIZE_OF_EACH_URI;
	else
		return -1;
}

int fill_with_response_headers(char *dest, int status_code, int content_length, int seconds_valid)
{
	// save the starting location
	char *write_ptr = dest;

	// append a reponse-line
	strcpy(write_ptr, "HTTP/1.1 ");
	write_ptr += sizeof("HTTP/1.1 ") - 1;
	switch (status_code) {
	case 200: 
		strcpy(write_ptr, "200 Ok\r\n");
		write_ptr += sizeof("200 Ok\r\n") - 1;
		break;
	case 201:
		strcpy(write_ptr, "201 Document Created\r\n");
		write_ptr += sizeof("201 Document Created\r\n") - 1;
		break;
	default:
		strcpy(write_ptr, "500 Internal server error while generating response headers\r\n");
		write_ptr += sizeof("500 Internal server error while generating response headers\r\n") - 1;
	}

	// append an HTTP-date line
	const char DAYS[128] = "Sun, Mon, Tue, Wed, Thu, Fri, Sat, xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
	const char MONTHS[128] = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
	const char ASCII_DIGIT_FACTOR = '1' - (char)1;
	construction_time now;
	strncpy(write_ptr, (DAYS + (5 * now.day_of_the_week)), 5);
	write_ptr += 5;
	*write_ptr++ = now.day_of_the_month / 10 + ASCII_DIGIT_FACTOR;
	*write_ptr++ = now.day_of_the_month % 10 + ASCII_DIGIT_FACTOR;
	*write_ptr++ = ' ';
	strncpy(write_ptr, (MONTHS + (4 * now.month)), 4);
	write_ptr += 4;
	*write_ptr++ = (now.hour / 10) + ASCII_DIGIT_FACTOR;
	*write_ptr++ = (now.hour % 10) + ASCII_DIGIT_FACTOR;
	*write_ptr++ = ':';
	*write_ptr++ = (now.minute / 10) + ASCII_DIGIT_FACTOR;
	*write_ptr++ = (now.minute % 10) + ASCII_DIGIT_FACTOR;
	*write_ptr++ = ':';
	*write_ptr++ = (now.second / 10) + ASCII_DIGIT_FACTOR;
	*write_ptr++ = (now.second % 10) + ASCII_DIGIT_FACTOR;
	strcpy(write_ptr, " GMT\r\n");
	write_ptr += sizeof(" GMT\r\n") - 1;

	// append a content-length line
	strcpy(write_ptr, "Content-Length: ");
	write_ptr += sizeof("Content-Length: ") - 1;
	for (int pwr_of_ten = MAXIMUM_CONTENT_LENGTH; pwr_of_ten > 0; pwr_of_ten /= 10)
	{
		int digit = (content_length / pwr_of_ten) % 10;
		if (digit || *(write_ptr-1) != ' ') {
			*write_ptr++ = digit + ASCII_DIGIT_FACTOR;
		}
	}
	*write_ptr++ = '\r';
	*write_ptr++ = '\n';

	// append a max-age line (HTTP/1.1)
	strcpy(write_ptr, "Cache-Control: max-age=");
	write_ptr += sizeof("Cache-Control: max-age=") -1;
	for (int pwr_of_ten = 10000000; pwr_of_ten > 0; pwr_of_ten /= 10)
	{
		int digit = (seconds_valid / pwr_of_ten) % 10;
		if (digit || *(write_ptr - 1) != ' ') {
			*write_ptr++ = digit + ASCII_DIGIT_FACTOR;
		}
	}
	*write_ptr++ = '\r';
	*write_ptr++ = '\n';

	// append trailing CRLF to indicate end of header metadata
	*write_ptr++ = '\r';
	*write_ptr++ = '\n';

	*write_ptr = '\0';
	return (write_ptr - dest);
}

inline bool case_insensitive_comparison(char char1, char char2)
{
	switch (char1) {
	case 'a': return (char2 == 'a' || char2 == 'A');
	case 'b': return (char2 == 'b' || char2 == 'B');
	case 'c': return (char2 == 'c' || char2 == 'C');
	case 'd': return (char2 == 'd' || char2 == 'D');
	case 'e': return (char2 == 'e' || char2 == 'E');
	case 'f': return (char2 == 'f' || char2 == 'F');
	case 'g': return (char2 == 'g' || char2 == 'G');
	case 'h': return (char2 == 'h' || char2 == 'H');
	case 'i': return (char2 == 'i' || char2 == 'I');
	case 'j': return (char2 == 'j' || char2 == 'J');
	case 'k': return (char2 == 'k' || char2 == 'K');
	case 'l': return (char2 == 'l' || char2 == 'L');
	case 'm': return (char2 == 'm' || char2 == 'M');
	case 'n': return (char2 == 'n' || char2 == 'N');
	case 'o': return (char2 == 'o' || char2 == 'O');
	case 'p': return (char2 == 'p' || char2 == 'P');
	case 'q': return (char2 == 'q' || char2 == 'Q');
	case 'r': return (char2 == 'r' || char2 == 'R');
	case 's': return (char2 == 's' || char2 == 'S');
	case 't': return (char2 == 't' || char2 == 'T');
	case 'u': return (char2 == 'u' || char2 == 'U');
	case 'v': return (char2 == 'v' || char2 == 'V');
	case 'w': return (char2 == 'w' || char2 == 'W');
	case 'x': return (char2 == 'x' || char2 == 'X');
	case 'y': return (char2 == 'y' || char2 == 'Y');
	case 'z': return (char2 == 'z' || char2 == 'Z');
	case 'A': return (char2 == 'a' || char2 == 'A');
	case 'B': return (char2 == 'b' || char2 == 'B');
	case 'C': return (char2 == 'c' || char2 == 'C');
	case 'D': return (char2 == 'd' || char2 == 'D');
	case 'E': return (char2 == 'e' || char2 == 'E');
	case 'F': return (char2 == 'f' || char2 == 'F');
	case 'G': return (char2 == 'g' || char2 == 'G');
	case 'H': return (char2 == 'h' || char2 == 'H');
	case 'I': return (char2 == 'i' || char2 == 'I');
	case 'J': return (char2 == 'j' || char2 == 'J');
	case 'K': return (char2 == 'k' || char2 == 'K');
	case 'L': return (char2 == 'l' || char2 == 'L');
	case 'M': return (char2 == 'm' || char2 == 'M');
	case 'N': return (char2 == 'n' || char2 == 'N');
	case 'O': return (char2 == 'o' || char2 == 'O');
	case 'P': return (char2 == 'p' || char2 == 'P');
	case 'Q': return (char2 == 'q' || char2 == 'Q');
	case 'R': return (char2 == 'r' || char2 == 'R');
	case 'S': return (char2 == 's' || char2 == 'S');
	case 'T': return (char2 == 't' || char2 == 'T');
	case 'U': return (char2 == 'u' || char2 == 'U');
	case 'V': return (char2 == 'v' || char2 == 'V');
	case 'W': return (char2 == 'w' || char2 == 'W');
	case 'X': return (char2 == 'x' || char2 == 'X');
	case 'Y': return (char2 == 'y' || char2 == 'Y');
	case 'Z': return (char2 == 'z' || char2 == 'Z');
	default: return (char1 == char2);
	}
}

inline char decode_uri_pct_character(char *second_hex)
{
	char decoded_char;
	switch (*second_hex)
	{
	default: decoded_char = 0x00; break;
	case '1': decoded_char = 0x01; break;
	case '2': decoded_char = 0x02; break;
	case '3': decoded_char = 0x03; break;
	case '4': decoded_char = 0x04; break;
	case '5': decoded_char = 0x05; break;
	case '6': decoded_char = 0x06; break;
	case '7': decoded_char = 0x07; break;
	case '8': decoded_char = 0x08; break;
	case '9': decoded_char = 0x09; break;
	case 'a': decoded_char = 0x0a; break;
	case 'A': decoded_char = 0x0a; break;
	case 'b': decoded_char = 0x0b; break;
	case 'B': decoded_char = 0x0b; break;
	case 'c': decoded_char = 0x0c; break;
	case 'C': decoded_char = 0x0c; break;
	case 'd': decoded_char = 0x0d; break;
	case 'D': decoded_char = 0x0d; break;
	case 'e': decoded_char = 0x0e; break;
	case 'E': decoded_char = 0x0e; break;
	case 'f': decoded_char = 0x0f; break;
	case 'F': decoded_char = 0x0f; break;
	}
	switch (*(second_hex - 1))
	{
	default: decoded_char += 0x00; break;
	case '1': decoded_char += 0x10; break;
	case '2': decoded_char += 0x20; break;
	case '3': decoded_char += 0x30; break;
	case '4': decoded_char += 0x40; break;
	case '5': decoded_char += 0x50; break;
	case '6': decoded_char += 0x60; break;
	case '7': decoded_char += 0x70; break;
	case '8': decoded_char += 0x80; break;
	case '9': decoded_char += 0x90; break;
	case 'a': decoded_char += 0xa0; break;
	case 'A': decoded_char += 0xa0; break;
	case 'b': decoded_char += 0xb0; break;
	case 'B': decoded_char += 0xb0; break;
	case 'c': decoded_char += 0xc0; break;
	case 'C': decoded_char += 0xc0; break;
	case 'd': decoded_char += 0xd0; break;
	case 'D': decoded_char += 0xd0; break;
	case 'e': decoded_char += 0xe0; break;
	case 'E': decoded_char += 0xe0; break;
	case 'f': decoded_char += 0xf0; break;
	case 'F': decoded_char += 0xf0; break;
	}
	return decoded_char;
}
