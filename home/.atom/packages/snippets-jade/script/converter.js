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

const SNIPPET_SRC_PATH = '../language-html/snippets/language-html.cson';
const SNIPPET_DIST_PATH = '../snippets/snippets-jade.cson';

const snippetConvert = (snippet, key, callback) => {
	const fixedSnippetBody = snippet['body']
		.replace(/\$/g, '__').replace('body', 'body_');

	html2jade.convertHtml(fixedSnippetBody,
		HTML2JADE_OPTIONS, (error, jade) => {
			snippet['body'] = jade
				.replace(/__/g, '$').replace(/body_/, 'body')
				.replace(/\| /, '').replace(/\n$/, '');

			callback(error);
		});
};

async.waterfall([
	fs.readFile.bind(null, SNIPPET_SRC_PATH), (file, callback) => {
		const snippetsRoot = CSON.parse(file.toString());
		const snippets = snippetsRoot[Object.keys(snippetsRoot)[0]];
		async.forEachOf(snippets, snippetConvert,
			error => callback(error, CSON.stringify({'.source.jade, .source.pug': snippets}, null, '\t')));
	},
	fs.writeFile.bind(null, SNIPPET_DIST_PATH)
], error => {
	if (error) throw error;
});
