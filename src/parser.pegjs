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
    = pairs:(keyValuePair '\n'*)* {
        return pairs.reduce(
            (seq, cur) => Object.assign(seq, cur[0]),
            Object.create(null)
        );
    }

keyValuePair
    = key:chars __ '=' __ value:valueElements {
        return {
            [key]: value
        };
    }

valueElements
    = valueElement*

valueElement
    = textElement
    / placeableElement

text
    = text:(__ chars __)+ {
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

textElement
    = text:text {
        return {
            type : 'textElement',
            value: text
        };
    }

expression
    = literalExpression
    / callExpression
    / memberExpression
    / argumentExpression
    / messageExpression

literalExpression
    = number:number {
        return {
            type: 'literalExpression',
            value: parseInt(number),
        }
    }

messageExpression
    = id:identifier {
         return {
              type: 'messageExpression',
              id: id
         }
    }

argumentExpression
    = '$' id:identifier {
         return {
              type: 'argumentExpression',
              id: id
         }
    }

callExpression
    = callee:builtin '(' __ arg:expression __ ')' {
        return {
            type: 'callExpression',
            callee: callee,
            args: [arg],
        };
    }

memberExpression
    = object:identifier '[' __ property:identifier __ ']' {
        return {
            type: 'memberExpression',
            object: object,
            property: property,
        };
    }

placeableElement
    = '{' _n expr:expression _n '}' {
        return {
            type    : 'placeableElement',
            expr    : expr,
        };
    }
    / '{' _n variants:(variant+) _n '}' {
        return {
            type    : 'placeableElement',
            variants: variants,
        };
    }
    / '{' _n expr:expression _n variants:('->' _n variant+) _n '}' {
        return {
            type    : 'placeableElement',
            expr    : expr,
            variants: variants[2],
        };
    }

selector
    = '[' __ sel:number __ ']' { return parseInt(sel); }
    / '[' __ sel:identifier __ ']' { return sel; }

variant
    = _n def:'*'? selector:selector __ pattern:valueElements {
        return {
            selector: selector,
            default: !!def,
            value   : pattern
        };
    }


// -- Helpers ------------------------------------------------------------------

__ 'optional single-line whitespace' = $([ \t]*)
_n 'optionalWhitespace' = $([ \t\n\r]*)

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

identifier = $([a-zA-Z0-9_?:-]+)
builtin    = $([A-Z0-9_?-]+)
