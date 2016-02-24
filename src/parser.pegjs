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
    / $(nbws)

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
    = callee:builtin '(' _ arg:expression _ ')' {
        return {
            type: 'callExpression',
            callee: callee,
            args: [arg],
        };
    }

memberExpression
    = object:identifier '[' _ property:identifier _ ']' {
        return {
            type: 'memberExpression',
            object: object,
            property: property,
        };
    }

placeableElement
    = '{' _ expr:expression _ '}' {
        return {
            type    : 'placeableElement',
            expr    : expr,
        };
    }
    / '{' _ variants:(variant+) _ '}' {
        return {
            type    : 'placeableElement',
            variants: variants,
        };
    }
    / '{' _ expr:expression _ variants:('->' _ variant+) _ '}' {
        return {
            type    : 'placeableElement',
            expr    : expr,
            variants: variants[2],
        };
    }

selector
    = '[' _ sel:number _ ']' { return parseInt(sel); }
    / '[' _ sel:identifier _ ']' { return sel; }

variant
    = _ def:'*'? selector:selector _ pattern:valueElements {
        return {
            selector: selector,
            default: !!def,
            value   : pattern
        };
    }

// -- Helpers ------------------------------------------------------------------


nbws 'non-breaking whitespace' = [ \t]+
__ 'optionalNonBreakingWhitespace' = $(nbws*)
ws 'whitespace' = [ \t\n\r]+
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
