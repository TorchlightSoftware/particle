// Generated by CoffeeScript 1.6.3
(function() {
  var getType, indexContaining, removers, _, _ref,
    _this = this,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = [].slice;

  removers = require('./enums').removers;

  _ref = require('./util'), indexContaining = _ref.indexContaining, _ = _ref._, getType = _ref.getType;

  module.exports = function(dataRoot, _arg) {
    var arrayIndex, arraySpec, data, id, index, location, node, op, operation, oplist, part, path, root, spec, subDoc, target, _i, _j, _k, _len, _len1, _ref1, _ref2;
    root = _arg.root, oplist = _arg.oplist;
    dataRoot[root] || (dataRoot[root] = []);
    for (_i = 0, _len = oplist.length; _i < _len; _i++) {
      op = oplist[_i];
      path = op.path, id = op.id, data = op.data, operation = op.operation;
      node = _.find(dataRoot[root], function(n) {
        return n.id === id;
      });
      if (!node) {
        if (__indexOf.call(removers, operation) >= 0) {
          return;
        } else {
          node = {
            id: id
          };
          dataRoot[root].push(node);
        }
      }
      if (path === '.') {
        target = dataRoot[root].indexOf(node);
        node = dataRoot[root];
        data = _.extend(data, {
          id: id
        });
      } else {
        _ref1 = path.split('.'), location = 2 <= _ref1.length ? __slice.call(_ref1, 0, _j = _ref1.length - 1) : (_j = 0, []), target = _ref1[_j++];
        for (_k = 0, _len1 = location.length; _k < _len1; _k++) {
          part = location[_k];
          arraySpec = part.match(/\[([0-9+])\]/);
          if (arraySpec) {
            spec = arraySpec[0], arrayIndex = arraySpec[1];
            arrayIndex = parseInt(arrayIndex);
            part = part.replace(spec, '');
          }
          if (node[part] == null) {
            if (__indexOf.call(removers, operation) >= 0) {
              return;
            } else {
              node[part] = arrayIndex ? [] : {};
            }
          }
          node = node[part];
          if (arrayIndex) {
            subDoc = _.find(node, function(item) {
              return item.id === arrayIndex;
            });
            if (subDoc == null) {
              if (__indexOf.call(removers, operation) >= 0) {
                return;
              } else {
                subDoc = {
                  id: arrayIndex
                };
                node.push(subDoc);
              }
            }
            node = subDoc;
          }
        }
      }
      switch (operation) {
        case 'set':
          node[target] = data;
          break;
        case 'unset':
          if (getType(node) === 'Array' && getType(target) === 'Number') {
            node.splice(target, 1);
          } else {
            delete node[target];
          }
          break;
        case 'inc':
          node[target] = (node[target] || 0) + (data || 1);
          break;
        case 'rename':
          node[data] = node[target];
          delete node[target];
          break;
        case 'push':
          node[target] || (node[target] = []);
          node[target].push(data);
          break;
        case 'pushAll':
          node[target] || (node[target] = []);
          (_ref2 = node[target]).push.apply(_ref2, data);
          break;
        case 'pop':
          if (data === -1) {
            node[target].splice(0, 1);
          } else {
            node[target].splice(-1, 1);
          }
          break;
        case 'pull':
          index = indexContaining(node[target], data);
          if (index != null) {
            node[target].splice(index, 1);
          }
      }
    }
  };

}).call(this);
