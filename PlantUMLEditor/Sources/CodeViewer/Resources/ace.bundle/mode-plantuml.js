ace.define("ace/mode/plantuml_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"], function(require, exports, module){/* ***** BEGIN LICENSE BLOCK *****
 * Distributed under the BSD license:
 *
 * Copyright (c) 2012, Ajax.org B.V.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Ajax.org B.V. nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL AJAX.ORG B.V. BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ***** END LICENSE BLOCK ***** */
"use strict";
var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
var PlantUMLHighlightRules = function () {
    this.$rules = {
        start: [{
                token: [
                    "diagram.source.wsd",
                    "keyword.control.diagram.source.wsd",
                    "diagram.source.wsd",
                    "diagram.source.wsd"
                ],
                regex: /^(\s*)(@start[a-z]+)((?:\s+.+?)?)(\s*$)/,
                caseInsensitive: true,
                push: [{
                        token: [
                            "diagram.source.wsd",
                            "keyword.control.diagram.source.wsd",
                            "diagram.source.wsd"
                        ],
                        regex: /^(\s*)(@end[a-z]+)(\s*$)/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        include: "#Quoted"
                    }, {
                        include: "#Comment"
                    }, {
                        include: "#Style"
                    }, {
                        include: "#Class"
                    }, {
                        include: "#Object"
                    }, {
                        include: "#Activity"
                    }, {
                        include: "#Sequence"
                    }, {
                        include: "#State"
                    }, {
                        include: "#Keywords"
                    }, {
                        include: "#General"
                    }, {
                        defaultToken: "diagram.source.wsd"
                    }],
                comment: "diagram block"
            }, {
                include: "#Quoted"
            }, {
                include: "#Comment"
            }, {
                include: "#Style"
            }, {
                include: "#Class"
            }, {
                include: "#Object"
            }, {
                include: "#Activity"
            }, {
                include: "#Sequence"
            }, {
                include: "#State"
            }, {
                include: "#Keywords"
            }, {
                include: "#General"
            }],
        "#Quoted": [{
                token: "support.variable.definitions.source.wsd",
                regex: /^\s*:/,
                caseInsensitive: true,
                push: [{
                        token: "support.variable.definitions.source.wsd",
                        regex: /:|[\];|<>\/}]?\s*$/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        defaultToken: "support.variable.definitions.source.wsd"
                    }],
                comment: "quoted definitions"
            }, {
                token: "string.quoted.double.source.wsd",
                regex: /"/,
                push: [{
                        token: "string.quoted.double.source.wsd",
                        regex: /"/,
                        next: "pop"
                    }, {
                        defaultToken: "string.quoted.double.source.wsd"
                    }],
                comment: "double quoted"
            }],
        "#Comment": [{
                token: "comment.line.comment.source.wsd",
                regex: /^\s*'/,
                caseInsensitive: true,
                push: [{
                        token: "comment.line.comment.source.wsd",
                        regex: /$/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        defaultToken: "comment.line.comment.source.wsd"
                    }],
                comment: "comment line"
            }, {
                token: "comment.block.source.wsd",
                regex: /\s*\/'/,
                caseInsensitive: true,
                push: [{
                        token: "comment.block.source.wsd",
                        regex: /'\/\s*/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        defaultToken: "comment.block.source.wsd"
                    }],
                comment: "comment block"
            }],
        "#Style": [{
                token: [
                    "text",
                    "keyword.other.skinparam.source.wsd",
                    "text",
                    "keyword.other.skinparam.keyword.source.wsd",
                    "constant.numeric.skinparam.keyword.source.wsd",
                    "text",
                    "string.quoted.double.skinparam.value.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(skinparam)(\s+)(\w+)((?:<<\s*.+?\s*>>)?)(\s+)([^\{\}]+?)(\s*$)/,
                caseInsensitive: true,
                comment: "inline style"
            }, {
                todo: {
                    token: [
                        "text",
                        "keyword.other.skinparam.source.wsd",
                        "text",
                        "keyword.other.skinparam.keyword.source.wsd",
                        "constant.numeric.skinparam.keyword.source.wsd",
                        "keyword.other.skinparam.keyword.source.wsd",
                        "constant.numeric.skinparam.keyword.source.wsd",
                        "text"
                    ],
                    regex: /^(\s*)(?:(skinparam)(?:(\s+)(\w+?)((?:<<\s*.+?\s*>>)?))?|(\w+)((?:<<\s*.+?\s*>>)?))(\s*\{\s*$)/,
                    caseInsensitive: true,
                    push: [{
                            token: "text",
                            regex: /^\s*(?<!\\)\}\s*$/,
                            next: "pop"
                        }, {
                            token: [
                                "text",
                                "keyword.other.skinparam.keyword.source.wsd",
                                "constant.numeric.skinparam.keyword.source.wsd",
                                "text",
                                "string.quoted.double.skinparam.value.source.wsd",
                                "text"
                            ],
                            regex: /^(\s*)(\w+)((?:<<\s*.+?\s*>>)?)(\s+)([^\{\}]+?)(\s*$)/,
                            caseInsensitive: true,
                            comment: "inline style"
                        }, {
                            include: "$self"
                        }]
                },
                comment: "style block"
            }],
        "#Keywords": [{
                token: "keyword.other.linebegin.source.wsd",
                regex: /^\s*(?:usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|enum|abstract\s+class|abstract|class|state|autonumber(?:\s+stop|\s+resume|\s+inc)?|activate|deactivate|return|destroy|newpage|alt|else|opt|loop|par|break|critical|group|box|rectangle|namespace|partition|agent|artifact|card|circle|collections|file|hexagon|label|person|queue|stack|storage|mainframe|map|repeat|backward|diamond|goto|binary|clock|concise|robust|compact\s+concise|compact\s+robust|json|protocol|struct)\b/,
                caseInsensitive: true,
                comment: "line begin keywords"
            }, {
                token: "keyword.other.wholeline.source.wsd",
                regex: /^\s*(?:split(?: again)?|endif|repeat|start|stop|end|end\s+fork|end\s+split|fork(?: again)?|detach|end\s+box|top\s+to\s+bottom\s+direction|left\s+to\s+right\s+direction|kill|end\s+merge|allow(?:_)?mixing)\s*$/,
                caseInsensitive: true,
                comment: "whole line keywords"
            }, {
                token: "keyword.other.other.source.wsd",
                regex: /\b(?:as|{(?:static|abstract)\})\b/,
                caseInsensitive: true,
                comment: "other keywords"
            }],
        "#General": [{
                token: [
                    "text",
                    "keyword.other.title.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(title)(\s*$)/,
                caseInsensitive: true,
                push: [{
                        token: ["text", "keyword.other.title.source.wsd"],
                        regex: /^(\s*\b)(end\s+title)\b/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        token: [
                            "text",
                            "entity.name.function.title.source.wsd",
                            "text"
                        ],
                        regex: /^(\s*)(.+?)(\s*$)/,
                        caseInsensitive: true
                    }],
                comment: "multi-line title, enables ctrl+r jump list."
            }, {
                token: [
                    "text",
                    "keyword.other.title.source.wsd",
                    "text",
                    "entity.name.function.title.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(title)(\s+)(.+?)(\s*$)/,
                caseInsensitive: true,
                comment: "title, enables ctrl+r jump list."
            }, {
                token: [
                    "keyword.other.scale.source.wsd",
                    "keyword.other.scale.source.wsd",
                    "keyword.other.scale.source.wsd",
                    "keyword.other.scale.source.wsd",
                    "keyword.other.scale.source.wsd",
                    "constant.numeric.scale.source.wsd",
                    "keyword.other.scale.source.wsd",
                    "keyword.operator.scale.source.wsd",
                    "keyword.other.scale.source.wsd",
                    "constant.numeric.scale.source.wsd",
                    "keyword.other.scale.source.wsd",
                    "keyword.other.scale.source.wsd"
                ],
                regex: /^(\s*)(scale)(\s+)(?:(max)(\s+))?(\d+(?:\.?\d+)?)(\s*)(?:([\*\/])(\s*)(\d+\.?(?:\.?\d+)?)|(width|height))?(\s*$)/,
                caseInsensitive: true,
                comment: "scale 1.5, scale 2/3, scale 200 width, scale 200 height, scale 200*100, scale max 300*200"
            }, {
                token: [
                    "text",
                    "keyword.other.note.source.wsd",
                    "text",
                    "constant.numeric.caption.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(caption)(\s+)(.+)(\s*$)/,
                caseInsensitive: true,
                comment: "inline caption"
            }, {
                token: [
                    "text",
                    "keyword.other.note.source.wsd",
                    "text",
                    "meta.comment.note.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(note\s(?:left|right))(\s*:\s*)(.+)(\s*$)/,
                caseInsensitive: true,
                comment: "inline note"
            }, {
                token: [
                    "text",
                    "keyword.other.note.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(note\s(?:left|right))(\s*$)/,
                caseInsensitive: true,
                push: [{
                        token: ["text", "keyword.other.note.source.wsd"],
                        regex: /^(\s*)(end\s*note)/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        token: "meta.comment.multiple.note.source.wsd",
                        regex: /.+?/
                    }],
                comment: "multiple note"
            }, {
                token: [
                    "text",
                    "keyword.other.noteof.source.wsd",
                    "text",
                    "constant.numeric.noteof.source.wsd",
                    "text",
                    "keyword.other.noteof.source.wsd",
                    "text",
                    "text",
                    "support.variable.noteof.source.wsd",
                    "text",
                    "support.variable.noteof.source.wsd",
                    "text",
                    "support.variable.noteof.source.wsd",
                    "keyword.other.noteof.source.wsd",
                    "text",
                    "constant.numeric.noteof.source.wsd",
                    "text",
                    "meta.comment.noteof.source.wsd"
                ],
                regex: /^(\s*)([rh]?note)(?:(\s+)(right|left|top|bottom))?(\s+)(?:(of|over)(\s*)(?:([^\s\w\d])([\w\s]+)([^\s\w\d])|(".+?"|\w+)(?:(,\s*)(".+?"|\w+))*)|(on\s+link))(\s*)((?:#\w+)?)(\s*:\s*)(.+)$/,
                caseInsensitive: true,
                comment: "inline note of over"
            }, {
                token: [
                    "text",
                    "keyword.other.noteof.source.wsd",
                    "text",
                    "constant.numeric.noteof.source.wsd",
                    "text",
                    "keyword.other.noteof.source.wsd",
                    "text",
                    "text",
                    "support.variable.noteof.source.wsd",
                    "text",
                    "support.variable.noteof.source.wsd",
                    "text",
                    "support.variable.noteof.source.wsd",
                    "keyword.other.noteof.source.wsd",
                    "text",
                    "constant.numeric.noteof.source.wsd",
                    "text"
                ],
                regex: /^(\s*)([rh]?note)(?:(\s+)(right|left|top|bottom))?(\s+)(?:(of|over)(\s*)(?:([^\s\w\d])([\w\s]+)([^\s\w\d])|(".+?"|\w+)(?:(,\s*)(".+?"|\w+))*)|(on\s+link))(\s*)((?:#\w+)?)(\s*$)/,
                caseInsensitive: true,
                push: [{
                        token: [
                            "text",
                            "keyword.other.multline.noteof.source.wsd"
                        ],
                        regex: /^(\s*)(end\s*[rh]?note)/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        token: "meta.comment.multline.noteof.source.wsd",
                        regex: /.+?/
                    }],
                comment: "multi-line note of over"
            }, {
                token: [
                    "text",
                    "keyword.other.noteas.source.wsd",
                    "text",
                    "meta.comment.noteas.source.wsd",
                    "text",
                    "keyword.other.noteas.source.wsd",
                    "text",
                    "support.variable.noteas.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(note)(\s+)(".+?")(\s+)(as)(\s+)([\w\d]+)(\s*$)/,
                caseInsensitive: true,
                comment: "float note, note as"
            }, {
                token: [
                    "text",
                    "constant.numeric.header_legend_footer.source.wsd",
                    "text",
                    "keyword.other.header_legend_footer.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(?:(center|left|right)(\s+))?(header|legend|footer)(\s*$)/,
                caseInsensitive: true,
                push: [{
                        token: [
                            "text",
                            "keyword.other.header_legend_footer.source.wsd"
                        ],
                        regex: /^(\s*)(end\s?(?:header|legend|footer))/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        token: "meta.comment.header_legend_footer.source.wsd",
                        regex: /.+?/
                    }],
                comment: "multi-line header, legend, footer"
            }, {
                token: [
                    "text",
                    "constant.numeric.header_legend_footer.source.wsd",
                    "text",
                    "keyword.other.header_legend_footer.source.wsd",
                    "text",
                    "meta.comment.header_legend_footer.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(?:(center|left|right)(\s+))?(header|legend|footer)(\s+)(.+?)(\s*$)/,
                caseInsensitive: true,
                comment: "header, legend, footer"
            }, {
                token: "entity.name.function.preprocessings.source.wsd",
                regex: /!includesub|!include|!enddefinelong|!definelong|!define|!startsub|!endsub|!ifdef|!else|!endif|!ifndef|!if|!elseif|!endif|!while|!endwhile|!(?:unquoted\s|final\s)*procedure|!(?:unquoted\s|final\s)*function|!end\s*(?:function|procedure)|!return|!import|!includedef|!includeurl|!include_many|!include_once|!log|!dump_memory|!theme|!pragma|!assume\s+transparent\s+(?:dark|light)/,
                caseInsensitive: true,
                comment: "Preprocessings"
            }, {
                token: [
                    "keyword.control.note.source.wsd",
                    "constant.numeric.link.color.source.wsd",
                    "constant.language.link.source.wsd"
                ],
                regex: /((?:\s+[ox]|[+*])?(?:<<|<\|?|\\\\|\\|\/\/|\}|\^|#|0|0\))?(?=[-.~=])[-.~=]+(?:\[\#(?:[0-9a-f]{6}|[0-9a-f]{3}|\w+)(?:[-\\\/](?:[0-9a-f]{6}|[0-9a-f]{3}|\w+))?\b\])?)(?:(left|right|up|down))?([-.]*(?:>>|\|?>|\\\\|\\|\/\/|\{|\^|#|0|\(0)?(?:[ox]\s+|[+*])?)/,
                caseInsensitive: true,
                push: [{
                        token: "text",
                        regex: /$/,
                        next: "pop"
                    }, {
                        include: "#General"
                    }, {
                        token: [
                            "text",
                            "support.variable.actor.link.source.wsd",
                            "text",
                            "meta.comment.message.link.source.wsd"
                        ],
                        regex: /(:)([^:]+)(:\s*:)(.+)$/,
                        caseInsensitive: true,
                        comment: "actor and link message"
                    }, {
                        token: [
                            "text",
                            "meta.comment.message.link.source.wsd"
                        ],
                        regex: /(:)(.+)$/,
                        caseInsensitive: true,
                        comment: "link message"
                    }],
                comment: "links"
            }, {
                token: "constant.numeric.colors.source.wsd",
                regex: /#(?:[0-9a-f]{6}|[0-9a-f]{3}|\w+)/,
                caseInsensitive: true,
                comment: "all color names"
            }, {
                token: "support.variable.source.wsd",
                regex: /\b[\w_]+/,
                comment: "Variables"
            }],
        "#Activity": [{
                token: [
                    "text",
                    "keyword.other.activity.if.source.wsd",
                    "text",
                    "string.quoted.double.activity.if.source.wsd",
                    "text",
                    "keyword.other.activity.if.source.wsd",
                    "text",
                    "meta.comment.activity.if.source.wsd",
                    "text",
                    "text"
                ],
                regex: /^(\s*)(else *if|if)(\s?\()(.+?)(\)\s?)(then)(?:(\s?\()(.+?)(\)))?(\s*$)/,
                caseInsensitive: true,
                comment: "if"
            }, {
                token: [
                    "text",
                    "keyword.other.activity.else.source.wsd",
                    "text",
                    "meta.comment.activity.else.source.wsd",
                    "text",
                    "text"
                ],
                regex: /^(\s*)(else)(?:(\s?\()(.+?)(\)))?(\s*$)/,
                caseInsensitive: true,
                comment: "else"
            }, {
                token: [
                    "text",
                    "keyword.other.activity.while.source.wsd",
                    "keyword.other.activity.while.source.wsd",
                    "text",
                    "string.quoted.double.activity.while.source.wsd",
                    "text",
                    "text",
                    "keyword.other.activity.while.source.wsd",
                    "text",
                    "meta.comment.activity.while.source.wsd",
                    "text",
                    "text"
                ],
                regex: /^(\s*)((?:repeat\s+)?)(while)(\s*\()(.+?)(\))(?:(\s*)(is)(?:(\s*\()(.+?)(\)))?)?(\s*$)/,
                caseInsensitive: true,
                comment: "while is, repeat while is"
            }, {
                token: [
                    "text",
                    "keyword.other.activity.endwhile.source.wsd",
                    "text",
                    "keyword.other.activity.endwhile.source.wsd",
                    "text",
                    "meta.comment.activity.endwhile.source.wsd",
                    "text",
                    "text"
                ],
                regex: /^(\s*)(end)(\s?)(while)(?:(\s*\()(.+?)(\)))?(\s*$)/,
                caseInsensitive: true,
                comment: "endwhile"
            }],
        "#Sequence": [{
                token: [
                    "text",
                    "keyword.operator.sequence.divider.source.wsd",
                    "text",
                    "string.quoted.double.sequence.divider.source.wsd",
                    "text",
                    "keyword.operator.sequence.divider.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(={2,})(\s*)(.+?)(\s*)(={2,})(\s*$)/,
                caseInsensitive: true,
                comment: "divider"
            }, {
                token: [
                    "text",
                    "keyword.operator.sequence.omission.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(\.{3,})(\s*$)/,
                caseInsensitive: true,
                comment: "..."
            }, {
                token: [
                    "text",
                    "keyword.other.sequence.ref.source.wsd",
                    "text",
                    "support.variable.sequence.ref.source.wsd",
                    "text",
                    "meta.comment.sequence.ref.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(ref\s+over)(\s+)(.+?)(\s*:\s*)(.+)(\s*$)/,
                caseInsensitive: true,
                comment: "inline ref"
            }, {
                token: [
                    "text",
                    "keyword.other.sequence.ref.source.wsd",
                    "text",
                    "support.variable.sequence.ref.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(ref\s+over)(\s+)(.+?)(\s*$)/,
                caseInsensitive: true,
                push: [{
                        token: "keyword.other.sequence.ref.source.wsd",
                        regex: /end\s+ref/,
                        caseInsensitive: true,
                        next: "pop"
                    }, {
                        token: "meta.comment.sequence.ref.source.wsd",
                        regex: /.+?/
                    }],
                comment: "multi-line ref"
            }, {
                token: [
                    "text",
                    "keyword.operator.sequence.delay.source.wsd",
                    "text",
                    "meta.comment.sequence.delay.source.wsd",
                    "text",
                    "keyword.operator.sequence.delay.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(\.{3,})(\s*)(.+)(\s*)(\.{3,})(\s*$)/,
                caseInsensitive: true,
                comment: "delay"
            }, {
                token: [
                    "keyword.operator.sequence.space.source.wsd",
                    "constant.numeric.sequence.space.source.wsd",
                    "keyword.operator.sequence.space.source.wsd"
                ],
                regex: /(\|{2,})((?:\d+)?)(\|{1,})/,
                caseInsensitive: true,
                comment: "space"
            }],
        "#State": [{
                token: [
                    "text",
                    "keyword.other.state.concurrent.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(-{2,})(\s*$)/,
                caseInsensitive: true,
                comment: "concurrent"
            }],
        "#Object": [{
                token: [
                    "text",
                    "support.variable.object.addfields.source.wsd",
                    "text"
                ],
                regex: /^(\s*)([\w\d_]+)(\s+:\s+s*$)/,
                caseInsensitive: true,
                comment: "add object fields"
            }],
        "#Class": [{
                token: [
                    "text",
                    "keyword.other.class.group.source.wsd",
                    "text",
                    "support.variable.class.group.source.wsd",
                    "text",
                    "string.quoted.double.class.definition.source.wsd",
                    "text",
                    "keyword.other.class.group.source.wsd",
                    "text",
                    "support.variable.class.group.source.wsd",
                    "text",
                    "string.quoted.double.class.definition.source.wsd",
                    "constant.numeric.class.definition.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(enum|abstract\s+class|abstract|class)(\s+)([\w\d_\.]+|"[^"]+")(?:(\s*)(<<.+?>>))?(?:(\s+)(as)(\s+)([\w\d_\.]+|"[^"]+")(?:(\s*)(<<.+?>>))?)?((?:\s+#[\w\|\\\/\-]+)?)(\s*\{\s*$)/,
                caseInsensitive: true,
                push: [{
                        token: "text",
                        regex: /^\s*(?<!\\)\}\s*$/,
                        next: "pop"
                    }, {
                        token: [
                            "text",
                            "meta.comment.class.group.separator.source.wsd",
                            "text",
                            "string.quoted.double.class.group.separator.source.wsd",
                            "text",
                            "meta.comment.class.group.separator.source.wsd"
                        ],
                        regex: /^(\s*)([.=_-]{2,})(\s*)(?:(.+?)(\s*)([.=_-]{2,}))?/,
                        caseInsensitive: true,
                        comment: "body separator"
                    }, {
                        token: [
                            "text",
                            "storage.modifier.class.function.source.wsd",
                            "keyword.other.class.function.source.wsd",
                            "support.type.class.function.source.wsd",
                            "support.variable.class.function.source.wsd",
                            "text",
                            "support.variable.class.function.source.wsd",
                            "text",
                            "text",
                            "support.type.class.function.source.wsd",
                            "text"
                        ],
                        regex: /^(\s*)((?:\s*\{(?:static|abstract)\}\s*)?)((?:\s*[~#+-]\s*)?)(?:((?:[\p{L}0-9_]+(?:\[\])?\s+)?)([\p{L}0-9_]+)(\(\))|([\p{L}0-9_]+)(\(\))(\s*:\s*)((?:[\p{L}0-9_]+)?))(\s*$)/,
                        caseInsensitive: true,
                        comment: "function"
                    }, {
                        token: [
                            "text",
                            "storage.modifier.class.fields.source.wsd",
                            "keyword.other.class.fields.source.wsd",
                            "support.type.class.fields.source.wsd",
                            "support.variable.class.fields.source.wsd",
                            "support.variable.class.fields.source.wsd",
                            "text",
                            "support.type.class.fields.source.wsd",
                            "text"
                        ],
                        regex: /^(\s*)((?:\s*\{(?:static|abstract)\}\s*)?)((?:\s*[~#+-]\s*)?)(?:((?:[\p{L}0-9_]+(?:\[\])?\s+)?)([\p{L}0-9_]+)|([\p{L}0-9_]+)(\s*:\s*)((?:\w+)?))(\s*$)/,
                        caseInsensitive: true,
                        comment: "fields"
                    }, {
                        token: [
                            "text",
                            "storage.modifier.class.fields.source.wsd",
                            "keyword.other.class.fields.source.wsd",
                            "string.quoted.double.class.other.source.wsd",
                            "text"
                        ],
                        regex: /^(\s*)((?:\s*\{(?:static|abstract)\}\s*)?)((?:\s*[~#+-]\s*)?)(.+?)(\s*$)/,
                        caseInsensitive: true,
                        comment: "other fields/function"
                    }],
                comment: "class group & enum"
            }, {
                token: [
                    "text",
                    "keyword.other.class.hideshow.source.wsd",
                    "text",
                    "support.variable.class.hideshow.source.wsd",
                    "text",
                    "constant.numeric.class.hideshow.source.wsd",
                    "text"
                ],
                regex: /^(\s*)(hide|show|remove)(\s+)((?:[\w\d_\.\$]+|"[^"]+")|<<.+?>>|Stereotypes|class|interface|enum|@unlinked)(?:(\s+)(empty fields|empty attributes|empty methods|empty description|fields|attributes|methods|members|circle))?(\s*$)/,
                caseInsensitive: true,
                comment: "hide & show & remove"
            }]
    };
    this.normalizeRules();
};
PlantUMLHighlightRules.metaData = {
    author: "jebbs, qjebbs@gmail.com",
    comment: "All diagram and styles support.",
    fileTypes: ["puml", "plantuml", "wsd"],
    name: "PlantUML",
    scopeName: "source.wsd"
};
oop.inherits(PlantUMLHighlightRules, TextHighlightRules);
exports.PlantUMLHighlightRules = PlantUMLHighlightRules;

});

ace.define("ace/mode/folding/cstyle",["require","exports","module","ace/lib/oop","ace/range","ace/mode/folding/fold_mode"], function(require, exports, module){"use strict";
var oop = require("../../lib/oop");
var Range = require("../../range").Range;
var BaseFoldMode = require("./fold_mode").FoldMode;
var FoldMode = exports.FoldMode = function (commentRegex) {
    if (commentRegex) {
        this.foldingStartMarker = new RegExp(this.foldingStartMarker.source.replace(/\|[^|]*?$/, "|" + commentRegex.start));
        this.foldingStopMarker = new RegExp(this.foldingStopMarker.source.replace(/\|[^|]*?$/, "|" + commentRegex.end));
    }
};
oop.inherits(FoldMode, BaseFoldMode);
(function () {
    this.foldingStartMarker = /([\{\[\(])[^\}\]\)]*$|^\s*(\/\*)/;
    this.foldingStopMarker = /^[^\[\{\(]*([\}\]\)])|^[\s\*]*(\*\/)/;
    this.singleLineBlockCommentRe = /^\s*(\/\*).*\*\/\s*$/;
    this.tripleStarBlockCommentRe = /^\s*(\/\*\*\*).*\*\/\s*$/;
    this.startRegionRe = /^\s*(\/\*|\/\/)#?region\b/;
    this._getFoldWidgetBase = this.getFoldWidget;
    this.getFoldWidget = function (session, foldStyle, row) {
        var line = session.getLine(row);
        if (this.singleLineBlockCommentRe.test(line)) {
            if (!this.startRegionRe.test(line) && !this.tripleStarBlockCommentRe.test(line))
                return "";
        }
        var fw = this._getFoldWidgetBase(session, foldStyle, row);
        if (!fw && this.startRegionRe.test(line))
            return "start"; // lineCommentRegionStart
        return fw;
    };
    this.getFoldWidgetRange = function (session, foldStyle, row, forceMultiline) {
        var line = session.getLine(row);
        if (this.startRegionRe.test(line))
            return this.getCommentRegionBlock(session, line, row);
        var match = line.match(this.foldingStartMarker);
        if (match) {
            var i = match.index;
            if (match[1])
                return this.openingBracketBlock(session, match[1], row, i);
            var range = session.getCommentFoldRange(row, i + match[0].length, 1);
            if (range && !range.isMultiLine()) {
                if (forceMultiline) {
                    range = this.getSectionRange(session, row);
                }
                else if (foldStyle != "all")
                    range = null;
            }
            return range;
        }
        if (foldStyle === "markbegin")
            return;
        var match = line.match(this.foldingStopMarker);
        if (match) {
            var i = match.index + match[0].length;
            if (match[1])
                return this.closingBracketBlock(session, match[1], row, i);
            return session.getCommentFoldRange(row, i, -1);
        }
    };
    this.getSectionRange = function (session, row) {
        var line = session.getLine(row);
        var startIndent = line.search(/\S/);
        var startRow = row;
        var startColumn = line.length;
        row = row + 1;
        var endRow = row;
        var maxRow = session.getLength();
        while (++row < maxRow) {
            line = session.getLine(row);
            var indent = line.search(/\S/);
            if (indent === -1)
                continue;
            if (startIndent > indent)
                break;
            var subRange = this.getFoldWidgetRange(session, "all", row);
            if (subRange) {
                if (subRange.start.row <= startRow) {
                    break;
                }
                else if (subRange.isMultiLine()) {
                    row = subRange.end.row;
                }
                else if (startIndent == indent) {
                    break;
                }
            }
            endRow = row;
        }
        return new Range(startRow, startColumn, endRow, session.getLine(endRow).length);
    };
    this.getCommentRegionBlock = function (session, line, row) {
        var startColumn = line.search(/\s*$/);
        var maxRow = session.getLength();
        var startRow = row;
        var re = /^\s*(?:\/\*|\/\/|--)#?(end)?region\b/;
        var depth = 1;
        while (++row < maxRow) {
            line = session.getLine(row);
            var m = re.exec(line);
            if (!m)
                continue;
            if (m[1])
                depth--;
            else
                depth++;
            if (!depth)
                break;
        }
        var endRow = row;
        if (endRow > startRow) {
            return new Range(startRow, startColumn, endRow, line.length);
        }
    };
}).call(FoldMode.prototype);

});

ace.define("ace/mode/plantuml",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/plantuml_highlight_rules","ace/mode/folding/cstyle"], function(require, exports, module){/* ***** BEGIN LICENSE BLOCK *****
 * Distributed under the BSD license:
 *
 * Copyright (c) 2012, Ajax.org B.V.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Ajax.org B.V. nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL AJAX.ORG B.V. BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ***** END LICENSE BLOCK ***** */
"use strict";
var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var PlantUMLHighlightRules = require("./plantuml_highlight_rules").PlantUMLHighlightRules;
var FoldMode = require("./folding/cstyle").FoldMode;
var Mode = function () {
    this.HighlightRules = PlantUMLHighlightRules;
    this.foldingRules = new FoldMode();
};
oop.inherits(Mode, TextMode);
(function () {
    this.$id = "ace/mode/plantuml";
    this.snippetFileId = "ace/snippets/plantuml";
}).call(Mode.prototype);
exports.Mode = Mode;

});                (function() {
                    ace.require(["ace/mode/plantuml"], function(m) {
                        if (typeof module == "object" && typeof exports == "object" && module) {
                            module.exports = m;
                        }
                    });
                })();
            