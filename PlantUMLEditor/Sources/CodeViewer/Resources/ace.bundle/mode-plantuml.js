define("ace/mode/plantuml_highlight_rules", 
    [
        "require",
        "exports",
        "module",
        "ace/lib/oop", 
        "ace/mode/text_highlight_rules"
    ], function(require, exports, module) {
    
    var oop = require("../lib/oop");
    var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

    var PlantUMLHighlightRules = function() {
        this.$rules = {
            start: [
                {
                    token: "keyword", // Keywords
                    regex: "\\b(?:participant|actor|boundary|control|entity|database|collections|queue|note)\\b"
                },
                {
                    token: "constant.language", // Preprocessor directives
                    regex: "@startuml|@enduml"
                },
                {
                    token: "string", // Description
                    regex: /".*?"/
                },
                {
                    token: "comment", // Comments
                    regex: /'.*$/
                },
                // Add more rules as needed
            ]
        };
    };

    oop.inherits(PlantUMLHighlightRules, TextHighlightRules);
    exports.PlantUMLHighlightRules = PlantUMLHighlightRules;
});


define("ace/mode/plantuml", 
    [
        "require",
        "exports",
        "module", 
        "ace/lib/oop", 
        "ace/mode/text", 
        "ace/mode/plantuml_highlight_rules"
    ], function(require, exports, module) {

    var oop = require("../lib/oop");
    var TextMode = require("./text").Mode;
    // var Tokenizer = require("ace/tokenizer").Tokenizer;
    var PlantUMLHighlightRules = require("./plantuml_highlight_rules").PlantUMLHighlightRules;

    var Mode = function() {
        this.HighlightRules = PlantUMLHighlightRules;
        this.$behaviour = this.$defaultBehaviour;
    };
    oop.inherits(Mode, TextMode);

    (function() {
        // Extra mode properties and methods can be defined here
        this.$id = "ace/mode/plantuml";
    }).call(Mode.prototype);

    exports.Mode = Mode;
});


(function() {
    window.require(["ace/mode/plantuml"], function(m) {
        if (typeof module == "object" && typeof exports == "object" && module) {
            module.exports = m;
        }
    });
})();