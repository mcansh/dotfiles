const async = require('async');
const fs = require('fs');
const _ = require('underscore');
const html2jade = require('html2jade');
const CSON = require('cson-parser');

const HTML2JADE_OPTIONS = {
	bodyless: true,
	donotencode: true,
	double: true,
	noemptypipe: true,
	tabs: true,
	numeric: true
};

const SNIPPET_SRC_PATH = 'language-html/snippets/language-html.cson';
const SNIPPET_DIST_PATH = 'snippets/snippets-jade.cson';

function htmltojade(html) {
	var jade;
	const cd = (error, result) => {
		if (error) throw error;
		jade = result;
	};
	html2jade.convertHtml(html, HTML2JADE_OPTIONS, cd);
	return jade;
}

function snippetConvert(snippet, key) {
	switch (key) {
		case 'Address':
			snippet['body'] = 'address${1:.$2}\n\t$3';
			break;
		case 'Area':
			snippet['body'] = 'area(${1:shape="${2:default}", }coords="$3"${4:, href="${5:#}", alt="$6"})\n$0';
			break;
		case 'Bi-Directional Isolation':
			snippet['body'] = 'bdi${1:(dir="${2:rtl}")} $3\n$0';
			break;
		case 'Button':
			snippet['body'] = 'button(type="${1:button}"${2:, name="${3:button}"}) $4\n$0';
			break;
		case 'Column':
			snippet['body'] = 'col${1:(span="${2:2}")}\n$0';
			break;
		case 'Data List':
			snippet['body'] = 'datalist${1:.$2} $3\n$0';
			break;
		case 'Details':
			snippet['body'] = 'details${1:(open)} $2\n$0';
			break;
		case 'Description List':
			snippet['body'] = 'dl${1:.$2} $3\n$0';
			break;
		case 'Label':
			snippet['body'] = 'label${1:(for="$2")} $3\n$0'
			break;
		case 'Meter':
			snippet['body'] = 'meter(value="$1"${2:, min="${3:0}", max="${4:100}"}) $5\n$0';
			break;
		case 'Object':
			snippet['body'] = 'object(${1:type="$2"}${3:, data="${4:https://}"}) $5\n$0';
			break;
		case 'Option':
			snippet['body'] = 'option${1:(value="$2")} $3\n$0';
			break;
		case 'Quote':
			snippet['body'] = 'q${1:(cite="$2")} $3\n$0';
			break;
		case 'Preformatted Text':
			snippet['body'] = 'pre $1\n$0';
			break;
		case 'Script':
			snippet['body'] = 'script${1:(type="${2:text/javascript}")}.\n\t$3';
			break;
		case 'Video':
			snippet['body'] =  'video(src="${1:videofile.ogg}"${2:, autoplay}${3:, poster="${4:posterimage.jpg}"}) $5'
			break;
		default:
			snippet['body'] = snippet['body']
				.replace(/\$/g, '__').replace('body', 'body_');
			snippet['body'] = htmltojade(snippet['body'])
				.replace(/__/g, '$').replace('body_', 'body')
				.replace(/\| /, '').replace(/\n$/, '');
	}

	return snippet;
};

async.waterfall([
	fs.readFile.bind(null, SNIPPET_SRC_PATH),
	(file, callback) => {
		const snippetsRoot = CSON.parse(file.toString());
		const snippets = snippetsRoot[Object.keys(snippetsRoot)[0]];
		_.map(snippets, snippetConvert);
		callback(null, CSON.stringify({'.source.jade, .source.pug': snippets}, null, '\t'));
	},
	fs.writeFile.bind(null, SNIPPET_DIST_PATH)
], error => {
	if (error) throw error;
});
