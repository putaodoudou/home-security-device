const cli = require('commander');
require('shelljs/global');

const nodemcuToolPath = 'node_modules/nodemcu-tool/bin'
const pathToSrc = '../../..'

const options = '--connection-delay 800 --optimize --baud 115200'

cli.command('upload').action(function () {
	var allFiles = ''

	ls('src/*.lua').forEach(function (filename) {
		allFiles += ` ${pathToSrc}/${filename}`
	});

	cd(nodemcuToolPath);
	
	exec('node nodemcu-tool reset', function () {
		require('child_process').execSync(
		`node nodemcu-tool upload ${allFiles} ${options}`,
		{stdio: 'inherit'});
	})
})

cli.command('sign').action(function () {
	cd(nodemcuToolPath);

	var command = `node nodemcu-tool run sign.lua`

	exec('node nodemcu-tool reset', function () {
		require('child_process')
			.execSync(`node nodemcu-tool run sign.lua`, {stdio: 'inherit'})
	})
})

cli.command('config').action(function () {
	cd(nodemcuToolPath);
	exec('node nodemcu-tool reset', function () {
		require('child_process').execSync(
		`node nodemcu-tool upload ${pathToSrc}/src/config.json ${options}`,
		{stdio: 'inherit'});
	})
});

cli.command('start').action(function () {
	cd(nodemcuToolPath);

	require('child_process').execSync('node nodemcu-tool terminal',
	{stdio: 'inherit'})
})

cli.command('*').action( function(c){
	console.error('Unknown command "' + c + '"');
	cli.outputHelp();
});

cli.parse(process.argv);