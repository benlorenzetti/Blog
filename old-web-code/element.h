/*  element.h
*/

#ifndef ELEMENT_H
#define ELEMENT_H

#include <string>
#include <cstdlib>
#include <vector>
#include <algorithm> // swap() for copy-swap-idiom, in equal to operator
using namespace std;

enum tag_t { DOCTYPE, HTML, HEAD, STYLE, BODY, DIV, P, BR, A, IMG, TITLE, META, HEADER, ARTICLE, FOOTER, H1, H2, H3, FORM };
enum attribute_t { CLASS, ID, HREF, SRC, ALT, WIDTH, LANG, CHARSET, ACTION };

class element
{
public:
	element(); // Use this constructor to start a new webpage (it will be the DOCTYPE element)
	element(unsigned int, tag_t, attribute_t, string, string);
	// @param: id of the parent element (0 would indicate the first element constucted)
	// @param: tag 
	// @param: attribute (optional)
	// @param: attribute value (optional, required if attribute given)
	// @param: plain text content (optional)
	element(unsigned int, tag_t, attribute_t, string);
	element(unsigned int, tag_t, string);
	element(unsigned int, tag_t);
	element(const element&);
	element& operator=(element);
	void add_plain_text_content(string);
	void add_attribute(attribute_t, string);
	string get_html();
private:
	int id;
	tag_t tag;
	vector <attribute_t> attr;
	vector <string> attr_val;
	vector <int> children; // positive int indicates another element's id, negative indicates an index into plain_text_children
	vector <string> plain_text_children;
	static vector <element *> instances;
};	vector <element *> element::instances;

element::element()
{
	instances.clear();
	instances.push_back(this);
	id = 0;
	tag = DOCTYPE;
}

element::element(unsigned int parent_id, tag_t new_tag, attribute_t opt_attr, string opt_attr_val, string content)
{
	id = instances.size();
	instances.push_back(this);
	tag = new_tag;
	attr.push_back(opt_attr);
	attr_val.push_back(opt_attr_val);
	children.push_back(-1);
	plain_text_children.push_back(content);
	if (parent_id <= instances.size())
		instances.at(parent_id)->children.push_back(id);
}

element::element(unsigned int parent_id, tag_t new_tag, attribute_t attribute, string value)
{
	id = instances.size();
	instances.push_back(this);
	tag = new_tag;
	attr.push_back(attribute);
	attr_val.push_back(value);
	if (parent_id <= instances.size())
		instances.at(parent_id)->children.push_back(id);
}


element::element(unsigned int parent_id, tag_t new_tag, string content)
{
	id = instances.size();
	instances.push_back(this);
	tag = new_tag;
	children.push_back(-1);
	plain_text_children.push_back(content);
	if (parent_id <= instances.size())
		instances.at(parent_id)->children.push_back(id);
}

element::element(unsigned int parent_id, tag_t new_tag)
{
	id = instances.size();
	instances.push_back(this);
	tag = new_tag;
	if (parent_id <= instances.size())
		instances.at(parent_id)->children.push_back(id);
}

element::element(const element& other) : 
	id(other.id), tag(other.tag), attr(other.attr), attr_val(other.attr_val), children(other.children), plain_text_children(other.plain_text_children)
{
	instances.at(id) = this;
}

element& element::operator=(element tmp_copy) {
	swap (id, tmp_copy.id);
	swap (tag, tmp_copy.tag);
	swap (attr, tmp_copy.attr);
	swap (attr_val, tmp_copy.attr_val);
	swap (children, tmp_copy.children);
	swap (plain_text_children, tmp_copy.plain_text_children);
	instances.at(id) = this;
	return *this;
}

void element::add_plain_text_content(string content)
{
	children.push_back(-1 * (1 + plain_text_children.size()));
	plain_text_children.push_back(content);
}

void element::add_attribute(attribute_t attribute, string value)
{
	attr.push_back(attribute);
	attr_val.push_back(value);
}

string element::get_html()
{
	string temp;
	switch (tag)
	{
	case DOCTYPE: temp = "<!DOCTYPE html>";
	case HTML: temp = "<html"; break;
	case HEAD: temp = "<head"; break;
	case STYLE: temp = "<style"; break;
	case BODY: temp = "<body"; break;
	case DIV: temp = "<div"; break;
	case P: temp = "<p"; break;
	case BR: temp = "<br />"; return temp;
	case A: temp = "<a"; break;
	case IMG: temp = "<img"; break;
	case TITLE: temp = "<title"; break;
	case META: temp = "<meta"; break;
	case HEADER: temp = "<header"; break;
	case ARTICLE: temp = "<article"; break;
	case FOOTER: temp = "<footer"; break;
	case H1: temp = "<h1"; break;
	case H2: temp = "<h2"; break;
	case H3: temp = "<h3"; break;
	case FORM: temp = "<form"; break;
	default: cout << "Error in element::get_html(): the tag is not switched.\n"; exit(EXIT_FAILURE);
	}
	for (int i = 0; i< attr.size(); i++)
	{
		switch (attr.at(i))
		{
		case CLASS: temp.append(" class=\""); break;
		case ID: temp.append(" id=\""); break;
		case HREF: temp.append(" href=\""); break;
		case SRC: temp.append(" src=\""); break;
		case ALT: temp.append(" alt=\""); break;
		case WIDTH: temp.append(" width=\""); break;
		case LANG: temp.append(" lang=\""); break;
		case CHARSET: temp.append(" charset=\""); break;
		case ACTION: temp.append(" action=\""); break;
		default: cout << "Error in element::get_html(): the attribute is not switched\n"; exit(EXIT_FAILURE);
		} temp.append(attr_val.at(i)); temp.append("\"");
	} temp.append(">");
	cout << "element " << id << " has " << children.size() << " children: ";
	for (int i=0; i< children.size(); i++)
		cout << children.at(i) << " ";
	cout << endl;
	for (int i = 0; i< children.size(); i++)
	{
		int child = children.at(i);
		if (child < 0) {
			int plain_text_index = (child * -1) -1;
			cout << "appending plain_text_children.at(" << plain_text_index << "): " << plain_text_children.at(plain_text_index) << endl;
			temp.append(plain_text_children.at(plain_text_index));
		}
		else {
			cout << "appending instances.at(" << child << ")\n";
			temp.append(instances.at(child)->get_html());
		}
	}
	switch (tag)
	{
	case DOCTYPE: break;
	case HTML: temp.append("</html>"); break;
	case HEAD: temp.append("</head>"); break;
	case STYLE: temp.append("</style>"); break;
	case BODY: temp.append("</body>"); break;
	case DIV: temp.append("</div>"); break;
	case P: temp.append("</p>"); break;
	case BR: break;
	case A: temp.append("</a>"); break;
	case IMG: temp.append("</img>"); break;
	case TITLE: temp.append("</title>"); break;
	case META: temp.append("</meta>"); break;
	case HEADER: temp.append("</header>"); break;
	case ARTICLE: temp.append("</article>"); break;
	case FOOTER: temp.append("</footer>"); break;
	case H1: temp.append("</h1>"); break;
	case H2: temp.append("</h2>"); break;
	case H3: temp.append("</h3>"); break;
	case FORM: temp.append("</form>"); break;
	default: cout << "Error in element::get_html(): the tag is not switched.\n"; exit(EXIT_FAILURE);
	}

	return temp;
}

#endif
