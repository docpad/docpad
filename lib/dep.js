/**
 * Apply the function {handler} to each element in the array
 * Return false in the {handler} to break the cycle.
 * @param {Function} handler
 * @version 1.0.1
 * @date August 20, 2010
 * @since June 30, 2010
 * @package jquery-sparkle {@link http://www.balupton/projects/jquery-sparkle}
 * @author Benjamin "balupton" Lupton {@link http://www.balupton.com}
 * @copyright (c) 2009-2010 Benjamin Arthur Lupton {@link http://www.balupton.com}
 * @license MIT License {@link http://creativecommons.org/licenses/MIT/}
 */
Array.prototype.each = function(handler){
	for (var i = 0; i < this.length; ++i) {
		var value = this[i];
		if ( handler.apply(value,[i,value]) === false ) {
			break;
		}
	}
	return this;
}

/**
 * Apply the function {handler} to each item in the object, ignoring inherited items.
 * Return false in the {handler} to break the cycle.
 * @param {Function} handler
 * @version 1.0.0
 * @date August 20, 2010
 * @since August 20, 2010
 * @package jquery-sparkle {@link http://www.balupton/projects/jquery-sparkle}
 * @author Benjamin "balupton" Lupton {@link http://www.balupton.com}
 * @copyright (c) 2009-2010 Benjamin Arthur Lupton {@link http://www.balupton.com}
 * @license MIT License {@link http://creativecommons.org/licenses/MIT/}
 */
Object.prototype.each = function(handler){
	// Check
	if ( typeof handler !== 'function' ) {
		throw new Exception('Object.prototype.each: Invalid input');
	}
	// Cycle
	for ( var key in this ) {
		// Check
		if ( !this.hasOwnProperty(key) ) {
			continue;
		}
		// Fire
		var value = this[key];
		if ( handler.apply(value,[key,value]) === false ) {
			break;
		}
	}
	// Chain
	return this;
};

/**
 * Extends the current object with the passed object(s), ignoring iherited properties.
 * @param {Object} ... The passed object(s) to extend the current object with
 * @version 1.0.0
 * @date August 20, 2010
 * @since August 20, 2010
 * @package jquery-sparkle {@link http://www.balupton/projects/jquery-sparkle}
 * @author Benjamin "balupton" Lupton {@link http://www.balupton.com}
 * @copyright (c) 2009-2010 Benjamin Arthur Lupton {@link http://www.balupton.com}
 * @license MIT License {@link http://creativecommons.org/licenses/MIT/}
 */
Object.prototype.extend = function(object){
	var Me = this;
	// Check
	if ( typeof object !== 'object' ) {
		throw new Exception('Object.prototype.extend: Invalid input');
	}
	// Handle
	if ( arguments.length > 1 ) {
		arguments.each(function(){
			Me.extend(this);
		});
	}
	else {
		// Extend
		object.each(function(key,object){
			if ( typeof object === 'object' ) {
				if ( object instanceof Array ) {
					Me[key] = [].extend(object);
				}
				else if ( typeof Me[key] === 'object' ) {
					var backup = Me[key];
					Me[key] = {}.extend(backup).extend(object);
				}
				else {
					Me[key] = {}.extend(object);
				}
			}
			else {
				Me[key] = object;
			}
		});
	}
	// Chain
	return this;
};

/**
 * Return a new string with any spaces trimmed the left and right of the string
 * @version 1.0.0
 * @date June 30, 2010
 * @package jquery-sparkle {@link http://www.balupton/projects/jquery-sparkle}
 * @author Benjamin "balupton" Lupton {@link http://www.balupton.com}
 * @copyright (c) 2009-2010 Benjamin Arthur Lupton {@link http://www.balupton.com}
 * @license MIT License {@link http://creativecommons.org/licenses/MIT/}
 */
String.prototype.trim = String.prototype.trim || function() {
	// Trim off any whitespace from the front and back
	return this.replace(/^\s+|\s+$/g, '');
};

/**
 * Return a new string with the value stripped from the left and right of the string
 * @version 1.1.1
 * @date July 22, 2010
 * @since 1.0.0, June 30, 2010
 * @package jquery-sparkle {@link http://www.balupton/projects/jquery-sparkle}
 * @author Benjamin "balupton" Lupton {@link http://www.balupton.com}
 * @copyright (c) 2009-2010 Benjamin Arthur Lupton {@link http://www.balupton.com}
 * @license MIT License {@link http://creativecommons.org/licenses/MIT/}
 */
String.prototype.strip = String.prototype.strip || function(value,regex){
	// Strip a value from left and right, with optional regex support (defaults to false)
	value = String(value);
	var str = this;
	if ( value.length ) {
		if ( !(regex||false) ) {
			// We must escape value as we do not want regex support
			value = value.replace(/([\[\]\(\)\^\$\.\?\|\/\\])/g, '\\$1');
		}
		str = str.replace(eval('/^'+value+'+|'+value+'+$/g'), '');
	}
	return String(str);
}
