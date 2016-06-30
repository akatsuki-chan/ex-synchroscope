var _akatsuki_chan$elm_aircraft$Native_XPath = function () {

  function getXPath (element) {
    if(element && element.parentNode) {
      var xpath = getXPath(element.parentNode) + '/' + element.tagName;
      var s = [];
      for(var i = 0; i < element.parentNode.childNodes.length; i++) {
        var e = element.parentNode.childNodes[i];
        if(e.tagName == element.tagName) {
          s.push(e);
        }
      }
      if(1 < s.length) {
        for(var i = 0; i < s.length; i++) {
          if(s[i] === element) {
            xpath += '[' + (i+1) + ']';
            break;
          }
        }
      }

      return xpath.toLowerCase();
    }

    return '';
  }
  return {
    getXPath: getXPath
  }
}();