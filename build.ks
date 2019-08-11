#![bin]

extern console, process

import '@zokugun/template'
import 'dotenv'
import 'execa'
import 'fs'
import 'ip'
import 'js-yaml' => yaml

dotenv.config()

const username = process.env.USERNAME

const chroot = fs.readFileSync('./install.zot', 'utf8')
const programs = yaml.safeLoad(fs.readFileSync('./programs.yaml', 'utf8'))

func line(line) => line.trim().replace(/\$HOME/g, `/home/\(username)`)

func printAurPackages() { // {{{
	const output = []

	for const group of programs {
		for const program in group when program.aur? {
			output.push(`arch-chroot /mnt /bin/su - \(username) << EOF`)
			output.push(`git clone --depth=1 \(program.aur) ~/aur-package`)
			output.push(`cd aur-package`)

			if program.premake? {
				output.push(line(program.premake))
			}

			output.push(`makepkg -s --noconfirm`)
			output.push(`EOF\n`)

			output.push(`arch-chroot /mnt /bin/bash << EOF`)
			output.push(`find /home/\(username)/aur-package -type f -name '*.pkg.*' -exec pacman -U --noconfirm {} \\;`)
			output.push(`rm -rf /home/\(username)/aur-package`)
			output.push(`EOF\n`)
		}
	}

	return output.join('\n')
} // }}}

func printCommand(command, root, user) { // {{{
	const output = command.user ? user : root

	if command is Array {
		for const command in command {
			printCommand(command, root, user)
		}
	}
	else if command is String {
		output.push(command)
	}
	else if command.shell != 'fish' {
		output.push(command.command)
	}
} // }}}

func printCommands() { // {{{
	const root = []
	const user = []

	for const group of programs {
		for const program in group {
			if program.command? {
				printCommand(program, root, user)
			}

			if program.postinstall? {
				printCommand(program.postinstall, root, user)
			}
		}
	}

	if root.length != 0 {
		if user.length != 0 {
			return	`arch-chroot /mnt /bin/bash << EOF\n`
				+	root.join('\n')
				+	`\nEOF\n`
				+	`\n`
				+	`arch-chroot /mnt /bin/su - \(username) << EOF\n`
				+	user.join('\n')
				+	`\nEOF\n`
		}
		else {
			return	`arch-chroot /mnt /bin/bash << EOF\n`
				+	root.join('\n')
				+	`\nEOF\n`

		}
	}
	else if user.length != 0 {
		return	`arch-chroot /mnt /bin/su - \(username) << EOF\n`
			+	user.join('\n')
			+	`\nEOF\n`
	}
	else {
		return ''
	}
} // }}}

func printFishCommand(command, output) { // {{{
	if command is Array {
		for const command in command {
			printFishCommand(command, output)
		}
	}
	else if command.shell == 'fish' {
		output.push(command.command)
	}
} // }}}

func printFishCommands() { // {{{
	const output = []

	for const group of programs {
		for const program in group {
			if program.postinstall? {
				printFishCommand(program.postinstall, output)
			}
		}
	}

	return	`arch-chroot /mnt /bin/su - \(username) << EOF\n`
		+	output.join('\n')
		+	`\nEOF\n`
} // }}}

func printPacmanPackages() { // {{{
	const packages = []

	for const group of programs {
		for const program in group when !?program.aur && !?program.command && !?program.yay {
			packages.push(program.name)
		}
	}

	return	`arch-chroot /mnt /bin/bash << EOF\n`
		+	`pacman -S --noconfirm \(packages.join(' '))\n`
		+	`EOF\n`
} // }}}

func printYayPackages() { // {{{
	const packages = []

	for const group of programs {
		for const program in group when program.yay? {
			packages.push(program.yay)
		}
	}

	return	`arch-chroot /mnt /bin/su - \(username) << EOF\n`
		+	`yay --noconfirm -S \(packages.join(' '))\n`
		+	`EOF\n`
} // }}}

const script = template.run(chroot, {
	ip: ip.address()
	hostname: process.env.HOSTNAME
	username: process.env.USERNAME
	password: process.env.PASSWORD
	rankmirrors: process.env.RANKMIRRORS
	timezone: process.env.TIMEZONE
	locale: process.env.LOCALE
	printPacmanPackages
	printAurPackages
	printYayPackages
	printCommands
	printFishCommands
}, {
	strip: false
})
// console.log(script)

fs.writeFileSync('./install.sh', script, 'utf8')

execa.shellSync('COPYFILE_DISABLE=1 tar cvfz root.tar.gz --exclude=user -C ../config/ .')
execa.shellSync('COPYFILE_DISABLE=1 tar cvfz user.tar.gz -C ../config/user/ .')