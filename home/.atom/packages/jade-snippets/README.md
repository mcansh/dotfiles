# atom-jade-snippets

### [each] each val in [ 1, 2 ]
    each ${1:val} in ${2:[ bla ]}
        ${4:div= ${1:val}}

### [for] for( var i = 0; i <= 0; i++ )
    - for( var ${1:i} = ${2:0}; ${1:i} ${3:<= 0}; ${1:i}${4:++} )
        $5

### [include] ./includes/file.jade
    include ${1:includes}/${2:file}.${3:jade}
    $4

### [var]
    - var ${1:name} = ${2:value}
    $3

### [doctype]
    doctype html
    $1

### [html]
    doctype html
    html(lang=${1:en})
        head
            title $1
        body
            $2

### [html5]
    'html5 template':
        'prefix': 'html5'
        'body': '''
            doctype html
                html(lang=${1:en})
                    head
                        title ${2:Untitled}
                        meta(charset='utf-8')
                        meta(name='viewport', content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no')
                        meta(name='description', content='description')
                        meta(name='keywords', content='keywords')
                        meta(name='author', content='author')
                        meta(name="robots", content="index, follow")

                        //- ----- link website ----- //
                        link(rel='icon' href='src/img/favicon.png' type='image/x-icon')

                        //- ----- CSS Files ----- //
                        link(rel='stylesheet', href='css/style.css')
                    body
                        $3

                        script(type='text/javascript', src='js/main.js')

### [markdown]
    ${1:# Markdown}
    $2

### [coffee]
    ${1:console.log 'This is coffee script'}
    $2

### [script.source]
    script(type='${1:text/javascript}', src='${2:js/main.js}', ${3:attr})
    $4

### [script.inline]
    script.
        $1

### [script.include]
    script
        include ${1:script.js}

### [link]
    link(rel='${1:stylesheet}', href='${2:css/style.css}', ${3:attr})
    $4

### [style.inline]
    style.
        $1

### [style.include]
    style
        include ${1:style.css}

### [a]
    a${1:.class}(href='${2:#}', title="${3:title}", ${4:attr}) ${5:link}
    $6

### [image]
    img${1:.class}(src='${2:source}', title="${3:title}", alt="${4:alt}", ${5:attr})
    $5

### [figure]
    figure
        img${1:.class}(src='${2:source}', title="${3:title}", alt="${4:alt}", ${5:attr})
        figcaption $6

### [ipsum]
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.




## Reference
---

Sublime plugin: [Sublime Text HTML Snippets](https://packagecontrol.io/packages/HTML%20Snippets) by [joshnh](https://packagecontrol.io/browse/authors/joshnh)
