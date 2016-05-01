const async = require('async');
const fs = require('fs');
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

const SNIPPET_SRC_PATH = '../src/snippets-html.cson';
const SNIPPET_DIST_PATH = '../snippets/snippets-jade.cson';

const snippetConvert = (snippet, key, callback) => {

	html2jade.convertHtml(snippet['body']
		.replace('$', '__').replace(':', '-----').replace('{', '----').replace('}', '---')
		.replace('body', 'body_'),
		HTML2JADE_OPTIONS, (error, jade) => {
			snippet['body'] = jade
				.replace(/__/g, '$').replace(/-----/g, ':').replace(/----/g, '{').replace(/---/g, '}')
				.replace(/body_/, 'body')
				.replace(/\| /, '').replace(/\n$/, '');

			callback(error);
			console.log(snippet['body']);
		});
};

async.waterfall([
	fs.readFile.bind(null, SNIPPET_SRC_PATH), (file, callback) => {
		const snippetsRoot = CSON.parse(file.toString());
		const snippets = snippetsRoot[Object.keys(snippetsRoot)[0]];
		async.forEachOf(snippets, snippetConvert,
			error => callback(error, CSON.stringify({'.source.jade': snippets})));
	},
	fs.writeFile.bind(null, SNIPPET_DIST_PATH)
], error => {
	if (error) throw error;
});
