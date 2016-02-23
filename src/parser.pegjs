/*
Copyright 2014, Yahoo! Inc. All rights reserved.
Copyrights licensed under the New BSD License.
See the accompanying LICENSE file for terms.
*/

/*
Inspired by and derivied from:
messageformat.js https://github.com/SlexAxton/messageformat.js
Copyright 2014 Alex Sexton
Apache License, Version 2.0
*/

start
    = pairs:(keyValuePair '\n'?)* {
        return pairs.reduce(
            (seq, cur) => Object.assign(seq, cur[0]),
            Object.create(null)
        );
    }

keyValuePair
    = key:chars _ '=' _ value:messageFormatPattern {
        return {
            [key]: value
        };
    }

messageFormatPattern
    = elements:messageFormatElement* {
        return {
            type    : 'messageFormatPattern',
            elements: elements
        };
    }

messageFormatElement
    = messageTextElement
    / argumentElement

messageText
    = text:(_ chars _)+ {
        var string = '',
            i, j, outerLen, inner, innerLen;

        for (i = 0, outerLen = text.length; i < outerLen; i += 1) {
            inner = text[i];

            for (j = 0, innerLen = inner.length; j < innerLen; j += 1) {
                string += inner[j];
            }
        }

        return string;
    }
    / $(ws)

messageTextElement
    = messageText:messageText {
        return {
            type : 'messageTextElement',
            value: messageText
        };
    }

argument
    = number
    / callExpression
    / identifier

callExpression
    = callee:builtin '(' _ arg:argument? _ ')' {
        return {
            type: 'callExpression',
            callee: callee,
            arg: arg,
        };
    }

argumentElement
    = '{' _ id:argument _ format:('->' _ selectFormat)? _ '}' {
        return {
            type  : 'argumentElement',
            id    : id,
            format: format && format[2]
        };
    }

selectFormat
    = options:optionalFormatPattern+ {
        return {
            type   : 'selectFormat',
            options: options
        };
    }

selector
    = '[' _ chars:chars _ ']' { return chars; }

optionalFormatPattern
    = _ selector:selector _ pattern:messageFormatPattern {
        return {
            type    : 'optionalFormatPattern',
            selector: selector,
            value   : pattern
        };
    }

// -- Helpers ------------------------------------------------------------------

ws 'whitespace' = [ \t]+
_ 'optionalWhitespace' = $(ws*)

digit    = [0-9]
hexDigit = [0-9a-f]i

number = digits:('0' / $([1-9] digit*)) {
    return parseInt(digits, 10);
}

char
    = [^=\[\]{}\\\0-\x1F\x7f \t\n\r]
    / '\\\\' { return '\\'; }
    / '\\#'  { return '\\#'; }
    / '\\{'  { return '\u007B'; }
    / '\\}'  { return '\u007D'; }
    / '\\u'  digits:$(hexDigit hexDigit hexDigit hexDigit) {
        return String.fromCharCode(parseInt(digits, 16));
    }

chars = chars:char+ { return chars.join(''); }

identifier = $([a-zA-Z0-9_?-]+)
builtin    = $([A-Z0-9_?-]+)
