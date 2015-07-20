var gulp = require('gulp');
var uglify = require('gulp-uglify');
var rename = require('gulp-rename');

gulp.task('release', function() {
  return gulp.src('src/*.js')
    .pipe(uglify({mangle: true}))
    .pipe(rename({extname: '.min.js'}))
    .pipe(gulp.dest('dist'));
});

gulp.task('default', ['release']);
