(function() {
var gcd = function(a, b) {
    return (function() {
        if(b == 0) {
            return a;
        } else {
            return gcd(b, (a % b));
        }
    })();
};
console.log((gcd(49, 35)));
})();
