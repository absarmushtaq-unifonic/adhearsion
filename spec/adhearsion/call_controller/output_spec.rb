# encoding: utf-8

require 'spec_helper'
require 'ruby_speech'

module Adhearsion
  class CallController
    describe Output do
      include CallControllerTestHelpers

      def expect_ssml_output(ssml, options = {})
        expect_component_execution Punchblock::Component::Output.new(options.merge(:ssml => ssml))
      end

      def expect_async_ssml_output(ssml, options = {})
        expect_message_waiting_for_response Punchblock::Component::Output.new(options.merge(:ssml => ssml))
      end

      def expect_url_output(url, options = {})
        component = Punchblock::Component::Output.new(options.merge(render_document: {value: url, content_type: "application/ssml+xml"}))
        expect_component_execution component
      end

      def expect_async_url_output(url, options = {})
        component = Punchblock::Component::Output.new(options.merge(render_document: {value: url, content_type: "application/ssml+xml"}))
        expect_message_waiting_for_response component
      end

      describe "#player" do
        it "should return a Player component targetted at the current controller" do
          player = controller.player
          expect(player).to be_a Output::Player
          expect(player.controller).to be controller
        end
      end

      describe "#async_player" do
        it "should return an AsyncPlayer component targetted at the current controller" do
          player = controller.async_player
          expect(player).to be_a Output::AsyncPlayer
          expect(player.controller).to be controller
        end
      end

      describe "#play_audio" do
        let(:audio_file) { "/sounds/boo.wav" }

        let :ssml do
          file = audio_file
          RubySpeech::SSML.draw { audio :src => file }
        end

        it 'plays the correct ssml' do
          expect_ssml_output ssml
          expect(subject.play_audio(audio_file)).to be true
        end

        context "with a fallback" do
          let(:fallback) { "text for tts" }

          let :ssml do
            file = audio_file
            fallback_text = fallback
            RubySpeech::SSML.draw do
              audio(:src => file) { fallback_text }
            end
          end

          it 'places the fallback in the SSML doc' do
            expect_ssml_output ssml
            expect(subject.play_audio(audio_file, :fallback => fallback)).to be true
          end
        end

        context "with a media engine" do
          let(:media_engine) { :native }
          it "should use the specified media engine in the component" do
            expect_ssml_output ssml, renderer: media_engine
            expect(subject.play_audio(audio_file, renderer: media_engine)).to be true
          end
        end
      end

      describe "#play_audio!" do
        let(:audio_file) { "/sounds/boo.wav" }

        let :ssml do
          file = audio_file
          RubySpeech::SSML.draw { audio :src => file }
        end

        it 'plays the correct ssml' do
          expect_async_ssml_output ssml
          expect(subject.play_audio!(audio_file)).to be_a Punchblock::Component::Output
        end

        context "with a fallback" do
          let(:fallback) { "text for tts" }

          let :ssml do
            file = audio_file
            fallback_text = fallback
            RubySpeech::SSML.draw do
              audio(:src => file) { fallback_text }
            end
          end

          it 'places the fallback in the SSML doc' do
            expect_async_ssml_output ssml
            expect(subject.play_audio!(audio_file, :fallback => fallback)).to be_a Punchblock::Component::Output
          end
        end

        context "with a media engine" do
          let(:media_engine) { :native }
          it "should use the specified media engine in the SSML" do
            expect_async_ssml_output ssml, renderer: media_engine
            expect(subject.play_audio!(audio_file, renderer: media_engine)).to be_a Punchblock::Component::Output
          end
        end
      end

      describe "#play_numeric" do
        let :ssml do
          RubySpeech::SSML.draw do
            say_as(:interpret_as => 'cardinal') { "123" }
          end
        end

        describe "with a number" do
          let(:input) { 123 }

          it 'plays the correct ssml' do
            expect_ssml_output ssml
            expect(subject.play_numeric(input)).to be true
          end
        end

        describe "with a string representation of a number" do
          let(:input) { "123" }

          it 'plays the correct ssml' do
            expect_ssml_output ssml
            expect(subject.play_numeric(input)).to be true
          end
        end

        describe "with something that's not a number" do
          let(:input) { 'foo' }

          it 'raises ArgumentError' do
            expect { subject.play_numeric input }.to raise_error(ArgumentError)
          end
        end

        context "with a renderer" do
          let(:input)     { 123 }
          let(:renderer)  { :native }

          it "should use the specified renderer in the SSML" do
            expect_ssml_output ssml, renderer: renderer
            expect(subject.play_numeric(input, renderer: renderer)).to be true
          end
        end
      end

      describe "#play_numeric!" do
        let :ssml do
          RubySpeech::SSML.draw do
            say_as(:interpret_as => 'cardinal') { "123" }
          end
        end

        describe "with a number" do
          let(:input) { 123 }

          it 'plays the correct ssml' do
            expect_async_ssml_output ssml
            expect(subject.play_numeric!(input)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a string representation of a number" do
          let(:input) { "123" }

          it 'plays the correct ssml' do
            expect_async_ssml_output ssml
            expect(subject.play_numeric!(input)).to be_a Punchblock::Component::Output
          end
        end

        describe "with something that's not a number" do
          let(:input) { 'foo' }

          it 'raises ArgumentError' do
            expect { subject.play_numeric! input }.to raise_error(ArgumentError)
          end
        end

        context "with a renderer" do
          let(:input)     { 123 }
          let(:renderer)  { :native }

          it "should use the specified renderer in the SSML" do
            expect_async_ssml_output ssml, renderer: renderer
            expect(subject.play_numeric!(input, renderer: renderer)).to be_a Punchblock::Component::Output
          end
        end
      end

      describe "#play_document" do
        describe "with a URL" do
          let(:input) { 'http://example.com/ex.ssml' }

          it 'plays the url' do
            expect_url_output input
            expect(subject.play_document(input)).to be true
          end
        end

        describe "with something that's not a URL" do
          let(:input) { 'ceci n\'est pas une url' }

          it 'raises ArgumentError' do
            expect { subject.play_document input }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#play_document!" do
        describe "with a URL" do
          let(:input) { 'http://example.com/ex.ssml' }

          it 'plays the url' do
            expect_async_url_output input
            expect(subject.play_document!(input)).to be_a Punchblock::Component::Output
          end
        end

        describe "with something that's not a URL" do
          let(:input) { 'ceci n\'est pas une url' }

          it 'raises ArgumentError' do
            expect { subject.play_document! input }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#play_time" do
        let :ssml do
          content = input.to_s
          opts    = expected_say_as_options
          RubySpeech::SSML.draw do
            say_as(opts) { content }
          end
        end

        describe "with a time" do
          let(:input) { Time.parse("12/5/2000") }
          let(:expected_say_as_options) { {:interpret_as => 'time'} }

          it 'plays the correct SSML' do
            expect_ssml_output ssml
            expect(subject.play_time(input)).to be true
          end
        end

        describe "with a date" do
          let(:input) { Date.parse('2011-01-23') }
          let(:expected_say_as_options) { {:interpret_as => 'date'} }

          it 'plays the correct SSML' do
            expect_ssml_output ssml
            expect(subject.play_time(input)).to be true
          end
        end

        describe "with a date and a say_as format" do
          let(:input)   { Date.parse('2011-01-23') }
          let(:format)  { "d-m-y" }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it 'plays the correct SSML' do
            expect_ssml_output ssml
            expect(subject.play_time(input, :format => format)).to be true
          end
        end

        describe "with a date and a strftime option" do
          let(:strftime)    { "%d-%m-%Y" }
          let(:base_input)  { Date.parse('2011-01-23') }
          let(:input)       { base_input.strftime(strftime) }
          let(:expected_say_as_options) { {:interpret_as => 'date'} }

          it 'plays the correct SSML' do
            expect_ssml_output ssml
            expect(subject.play_time(base_input, :strftime => strftime)).to be true
          end
        end

        describe "with a date, a format option and a strftime option" do
          let(:strftime)    { "%d-%m-%Y" }
          let(:format)      { "d-m-y" }
          let(:base_input)  { Date.parse('2011-01-23') }
          let(:input)       { base_input.strftime(strftime) }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it 'plays the correct SSML' do
            expect_ssml_output ssml
            expect(subject.play_time(base_input, :format => format, :strftime => strftime)).to be true
          end
        end

        context "with a renderer" do
          let(:renderer)  { :native }
          let(:input)     { Date.parse('2011-01-23') }
          let(:format)    { "d-m-y" }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it "should use the specified renderer in the SSML" do
            expect_ssml_output ssml, renderer: renderer
            expect(subject.play_time(input, format: format, renderer: renderer)).to be true
          end
        end

        describe "with an object other than Time, DateTime, or Date" do
          let(:input) { "foo" }

          it 'raises ArgumentError' do
            expect { subject.play_time input }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#play_time!" do
        let :ssml do
          content = input.to_s
          opts    = expected_say_as_options
          RubySpeech::SSML.draw do
            say_as(opts) { content }
          end
        end

        describe "with a time" do
          let(:input) { Time.parse("12/5/2000") }
          let(:expected_say_as_options) { {:interpret_as => 'time'} }

          it 'plays the correct SSML' do
            expect_async_ssml_output ssml
            expect(subject.play_time!(input)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a date" do
          let(:input) { Date.parse('2011-01-23') }
          let(:expected_say_as_options) { {:interpret_as => 'date'} }

          it 'plays the correct SSML' do
            expect_async_ssml_output ssml
            expect(subject.play_time!(input)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a date and a say_as format" do
          let(:input)   { Date.parse('2011-01-23') }
          let(:format)  { "d-m-y" }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it 'plays the correct SSML' do
            expect_async_ssml_output ssml
            expect(subject.play_time!(input, :format => format)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a date and a strftime option" do
          let(:strftime)    { "%d-%m-%Y" }
          let(:base_input)  { Date.parse('2011-01-23') }
          let(:input)       { base_input.strftime(strftime) }
          let(:expected_say_as_options) { {:interpret_as => 'date'} }

          it 'plays the correct SSML' do
            expect_async_ssml_output ssml
            expect(subject.play_time!(base_input, :strftime => strftime)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a date, a format option and a strftime option" do
          let(:strftime)    { "%d-%m-%Y" }
          let(:format)      { "d-m-y" }
          let(:base_input)  { Date.parse('2011-01-23') }
          let(:input)       { base_input.strftime(strftime) }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it 'plays the correct SSML' do
            expect_async_ssml_output ssml
            expect(subject.play_time!(base_input, :format => format, :strftime => strftime)).to be_a Punchblock::Component::Output
          end
        end

        context "with a renderer" do
          let(:renderer)  { :native }
          let(:input)     { Date.parse('2011-01-23') }
          let(:format)    { "d-m-y" }
          let(:expected_say_as_options) { {:interpret_as => 'date', :format => format} }

          it "should use the specified renderer in the SSML" do
            expect_async_ssml_output ssml, renderer: renderer
            expect(subject.play_time!(input, format: format, renderer: renderer)).to be_a Punchblock::Component::Output
          end
        end

        describe "with an object other than Time, DateTime, or Date" do
          let(:input) { "foo" }

          it 'raises ArgumentError' do
            expect { subject.play_time! input }.to raise_error(ArgumentError)
          end
        end
      end

      describe '#play' do
        let(:extra_options) do
          { renderer: :native }
        end

        describe "with a nil argument" do
          it "is a noop" do
            subject.play nil
          end
        end

        describe "with a single string" do
          let(:audio_file) { "/foo/bar.wav" }
          let :ssml do
            file = audio_file
            RubySpeech::SSML.draw { audio :src => file }
          end

          it 'plays the audio file' do
            expect_ssml_output ssml
            expect(subject.play(audio_file)).to be true
          end

          it 'plays the audio file with the specified extra options if present' do
            expect_ssml_output ssml, extra_options
            expect(subject.play(audio_file, extra_options)).to be true
          end
        end

        describe "with multiple arguments" do
          let(:args) { ["/foo/bar.wav", 1, Time.now, "123#"] }
          let :ssml do
            file = args[0]
            n = args[1].to_s
            t = args[2].to_s
            c = args[3].to_s
            RubySpeech::SSML.draw do
              audio :src => file
              say_as(:interpret_as => 'cardinal') { n }
              say_as(:interpret_as => 'time') { t }
              say_as(:interpret_as => 'characters') { c }
            end
          end

          it 'plays all arguments in one document' do
            expect_ssml_output ssml
            expect(subject.play(*args)).to be true
          end

          it 'plays all arguments in one document with the extra options if present' do
            expect_ssml_output ssml, extra_options
            args << extra_options
            expect(subject.play(*args)).to be true
          end
        end

        describe "with a collection of arguments" do
          let(:args) { ["/foo/bar.wav", 1, Time.now] }
          let :ssml do
            file = args[0]
            n = args[1].to_s
            t = args[2].to_s
            RubySpeech::SSML.draw do
              audio :src => file
              say_as(:interpret_as => 'cardinal') { n }
              say_as(:interpret_as => 'time') { t }
            end
          end

          it 'plays all arguments in one document' do
            expect_ssml_output ssml
            expect(subject.play(args)).to be true
          end

          context "that is empty" do
            it "is a noop" do
              subject.play []
            end
          end
        end

        describe "with a number" do
          let(:argument) { 123 }

          let(:ssml) do
            number = argument.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { number }
            end
          end

          it 'plays the number' do
            expect_ssml_output ssml
            expect(subject.play(argument)).to be true
          end
        end

        describe "with a string representation of a number" do
          let(:argument) { '123' }

          let(:ssml) do
            number = argument
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { number }
            end
          end

          it 'plays the number' do
            expect_ssml_output ssml
            expect(subject.play(argument)).to be true
          end
        end

        describe "with a time" do
          let(:time) { Time.parse "12/5/2000" }

          let(:ssml) do
            t = time.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'time') { t }
            end
          end

          it 'plays the time' do
            expect_ssml_output ssml
            expect(subject.play(time)).to be true
          end
        end

        describe "with a date" do
          let(:date) { Date.parse '2011-01-23' }
          let(:ssml) do
            d = date.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'date') { d }
            end
          end

          it 'plays the time' do
            expect_ssml_output ssml
            expect(subject.play(date)).to be true
          end
        end

        describe "with an hash containing a Date/DateTime/Time object and format options" do
          let(:date)      { Date.parse '2011-01-23' }
          let(:format)    { "d-m-y" }
          let(:strftime)  { "%d-%m%Y" }

          let :ssml do
            d = date.strftime strftime
            f = format
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'date', :format => f) { d }
            end
          end

          it 'plays the time with the specified format and strftime' do
            expect_ssml_output ssml
            expect(subject.play(:value => date, :format => format, :strftime => strftime)).to be true
          end
        end

        describe "with an SSML document" do
          let(:ssml) { RubySpeech::SSML.draw { string "Hello world" } }

          it "plays the SSML without generating" do
            expect_ssml_output ssml
            expect(subject.play(ssml)).to be true
          end
        end
      end

      describe '#play!' do
        let(:extra_options) do
          { renderer: :native }
        end

        describe "with a nil argument" do
          it "is a noop" do
            subject.play! nil
          end
        end

        describe "with a single string" do
          let(:audio_file) { "/foo/bar.wav" }
          let :ssml do
            file = audio_file
            RubySpeech::SSML.draw { audio :src => file }
          end

          it 'plays the audio file' do
            expect_async_ssml_output ssml
            expect(subject.play!(audio_file)).to be_a Punchblock::Component::Output
          end

          it 'plays the audio file with the specified extra options if present' do
            expect_async_ssml_output ssml, extra_options
            subject.play!(audio_file, extra_options)
          end
        end

        describe "with multiple arguments" do
          let(:args) { ["/foo/bar.wav", 1, Time.now] }
          let :ssml do
            file = args[0]
            n = args[1].to_s
            t = args[2].to_s
            RubySpeech::SSML.draw do
              audio :src => file
              say_as(:interpret_as => 'cardinal') { n }
              say_as(:interpret_as => 'time') { t }
            end
          end

          it 'plays all arguments in one document' do
            expect_async_ssml_output ssml
            expect(subject.play!(*args)).to be_a Punchblock::Component::Output
          end

          it 'plays all arguments in one document with the extra options if present' do
            expect_async_ssml_output ssml, extra_options
            args << extra_options
            subject.play!(*args)
          end
        end

        describe "with a number" do
          let(:argument) { 123 }

          let(:ssml) do
            number = argument.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { number }
            end
          end

          it 'plays the number' do
            expect_async_ssml_output ssml
            expect(subject.play!(argument)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a string representation of a number" do
          let(:argument) { '123' }

          let(:ssml) do
            number = argument
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'cardinal') { number }
            end
          end

          it 'plays the number' do
            expect_async_ssml_output ssml
            expect(subject.play!(argument)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a time" do
          let(:time) { Time.parse "12/5/2000" }

          let(:ssml) do
            t = time.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'time') { t }
            end
          end

          it 'plays the time' do
            expect_async_ssml_output ssml
            expect(subject.play!(time)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a date" do
          let(:date) { Date.parse '2011-01-23' }
          let(:ssml) do
            d = date.to_s
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'date') { d }
            end
          end

          it 'plays the time' do
            expect_async_ssml_output ssml
            expect(subject.play!(date)).to be_a Punchblock::Component::Output
          end
        end

        describe "with an array containing a Date/DateTime/Time object and a hash" do
          let(:date)      { Date.parse '2011-01-23' }
          let(:format)    { "d-m-y" }
          let(:strftime)  { "%d-%m%Y" }

          let :ssml do
            d = date.strftime strftime
            f = format
            RubySpeech::SSML.draw do
              say_as(:interpret_as => 'date', :format => f) { d }
            end
          end

          it 'plays the time with the specified format and strftime' do
            expect_async_ssml_output ssml
            expect(subject.play!(:value => date, :format => format, :strftime => strftime)).to be_a Punchblock::Component::Output
          end
        end

        describe "with an SSML document" do
          let(:ssml) { RubySpeech::SSML.draw { string "Hello world" } }

          it "plays the SSML without generating" do
            expect_async_ssml_output ssml
            expect(subject.play!(ssml)).to be_a Punchblock::Component::Output
          end
        end
      end

      describe "#interruptible_play" do
        let(:output1)       { "one two" }
        let(:output2)       { "three four" }
        let(:non_existing)  { "http://adhearsion.com/nonexistingfile.mp3" }
        let(:extra_options) { {renderer: :native } }

        it "plays two outputs in succession" do
          expect(subject).to receive(:stream_file).twice
          digit = subject.interruptible_play output1, output2
          expect(digit).to be_nil
        end

        it "stops at the first play when input is received" do
          expect(subject).to receive(:stream_file).once.and_return(2)
          digit = subject.interruptible_play output1, output2
          expect(digit).to eq(2)
        end

        it "passes options on to #stream_file" do
          expect(subject).to receive(:stream_file).once.with(output1, '0123456789#*', extra_options)
          expect(subject).to receive(:stream_file).once.with(output2, '0123456789#*', extra_options)
          digit = subject.interruptible_play output1, output2, extra_options
          expect(digit).to be_nil
        end

        it 'raises an exception when output is unsuccessful' do
          expect(subject).to receive(:stream_file).once.and_raise Output::PlaybackError, "Output failed"
          expect { subject.interruptible_play non_existing }.to raise_error(Output::PlaybackError)
        end
      end

      describe "#stream_file" do
        let(:allowed_digits)  { '35' }
        let(:prompt)          { "Press 3 or 5 to make something happen." }

        let(:ssml) do
          RubySpeech::SSML.draw do
            string "Press 3 or 5 to make something happen."
          end
        end

        let(:grammar) do
          RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'acceptdigits' do
            rule id: 'acceptdigits' do
              one_of do
                allowed_digits.each { |d| item { d.to_s } }
              end
            end
          end
        end

        let(:output_component) {
          Punchblock::Component::Output.new :ssml => ssml.to_s
        }

        let(:input_component) {
          Punchblock::Component::Input.new :mode => :dtmf,
                                           :grammar => { :value => grammar.to_s }
        }

        def expect_component_complete_event
          expect_input_component_complete_event 'dtmf-5'
        end

        #test does pass and method works, but not sure if the empty method is a good idea
        it "plays the correct output" do
          allow(controller).to receive(:write_and_await_response)

          expect_component_complete_event
          expect_component_execution Punchblock::Component::Output.new(:ssml => ssml)
          subject.stream_file prompt, allowed_digits
        end

        it "returns a single digit amongst the allowed when pressed" do
          expect(controller).to receive(:write_and_await_response).with(kind_of(Punchblock::Component::Input)) do |input_component|
            input_component.trigger_event_handler Punchblock::Event::Complete.new
          end

          expect(controller).to receive(:write_and_await_response).once.with(kind_of(Punchblock::Component::Output))

          expect_any_instance_of(Punchblock::Component::Output).to receive(:stop!)
          expect_any_instance_of(Punchblock::Component::Output).to receive(:complete_event).and_return double('complete', reason: double('Reason'))
          expect_input_component_complete_event 'dtmf-5'

          expect(subject.stream_file(prompt, allowed_digits)).to eq('5')
        end

        context "with output options passed in" do
          let(:extra_options) { {renderer: :native } }
          it "plays the correct output with options" do
            allow(controller).to receive(:write_and_await_response)

            expect_component_complete_event
            expect_component_execution Punchblock::Component::Output.new({:ssml => ssml}.merge(extra_options))
            subject.stream_file prompt, allowed_digits, extra_options
          end
        end
      end

      describe "#say" do
        describe "with a nil argument" do
          it "is a no-op" do
            subject.say nil
          end
        end

        describe "with a RubySpeech document" do
          it 'plays the correct SSML' do
            ssml = RubySpeech::SSML.draw { string "Hello world" }
            expect_ssml_output ssml
            expect(subject.say(ssml)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a string" do
          it 'outputs the correct text' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_ssml_output ssml
            expect(subject.say(str)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a default voice set in PB config" do
          before { Adhearsion.config.punchblock.default_voice = 'foo' }

          it 'sets the voice on the output component' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_ssml_output ssml, voice: 'foo'
            subject.say(str)
          end

          after { Adhearsion.config.punchblock.default_voice = nil }
        end

        describe "with a default voice set in core and PB config" do
          before do
            Adhearsion.config.punchblock.default_voice = 'foo'
            Adhearsion.config.platform.media.default_voice = 'bar'
          end

          it 'prefers core config to set the voice on the output component' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_ssml_output ssml, voice: 'bar'
            subject.say(str)
          end

          after do
            Adhearsion.config.punchblock.default_voice = nil
            Adhearsion.config.platform.media.default_voice = nil
          end
        end

        describe "with a default media engine set in PB config" do
          before { Adhearsion.config.punchblock.media_engine = 'foo' }

          it 'sets the renderer on the output component' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_ssml_output ssml, renderer: 'foo'
            subject.say(str)
          end

          after { Adhearsion.config.punchblock.media_engine = nil }
        end

        describe "with a default renderer set in core and PB config" do
          before do
            Adhearsion.config.punchblock.media_engine = 'foo'
            Adhearsion.config.platform.media.default_renderer = 'bar'
          end

          it 'prefers core config to set the renderer on the output component' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_ssml_output ssml, renderer: 'bar'
            subject.say(str)
          end

          after do
            Adhearsion.config.punchblock.media_engine = nil
            Adhearsion.config.platform.media.default_renderer = nil
          end
        end

        describe "converts the argument to a string" do
          it 'calls output with a string' do
            argument = 123
            ssml = RubySpeech::SSML.draw { string '123' }
            expect_ssml_output ssml
            expect(subject.say(argument)).to be_a Punchblock::Component::Output
          end
        end
      end

      describe "#speak" do
        it "should be an alias for #say" do
          expect(subject.method(:speak)).to eq(subject.method(:say))
        end
      end

      describe "#say!" do
        describe "with a nil argument" do
          it "is a noop" do
            subject.say! nil
          end
        end

        describe "with a RubySpeech document" do
          it 'plays the correct SSML' do
            ssml = RubySpeech::SSML.draw { string "Hello world" }
            expect_async_ssml_output ssml
            expect(subject.say!(ssml)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a string" do
          it 'outputs the correct text' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_async_ssml_output ssml
            expect(subject.say!(str)).to be_a Punchblock::Component::Output
          end
        end

        describe "with a default voice set in PB config" do
          before { Adhearsion.config.punchblock.default_voice = 'foo' }

          it 'sets the voice on the output component' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_async_ssml_output ssml, voice: 'foo'
            subject.say!(str)
          end

          after { Adhearsion.config.punchblock.default_voice = nil }
        end

        describe "with a default voice set in core and PB config" do
          before do
            Adhearsion.config.punchblock.default_voice = 'foo'
            Adhearsion.config.platform.media.default_voice = 'bar'
          end

          it 'prefers core config to set the voice on the output component' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_async_ssml_output ssml, voice: 'bar'
            subject.say!(str)
          end

          after do
            Adhearsion.config.punchblock.default_voice = nil
            Adhearsion.config.platform.media.default_voice = nil
          end
        end

        describe "with a default media engine set in PB config" do
          before { Adhearsion.config.punchblock.media_engine = 'foo' }

          it 'sets the renderer on the output component' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_async_ssml_output ssml, renderer: 'foo'
            subject.say!(str)
          end

          after { Adhearsion.config.punchblock.media_engine = nil }
        end

        describe "with a default renderer set in core and PB config" do
          before do
            Adhearsion.config.punchblock.media_engine = 'foo'
            Adhearsion.config.platform.media.default_renderer = 'bar'
          end

          it 'prefers core config to set the renderer on the output component' do
            str = "Hello world"
            ssml = RubySpeech::SSML.draw { string str }
            expect_async_ssml_output ssml, renderer: 'bar'
            subject.say!(str)
          end

          after do
            Adhearsion.config.punchblock.media_engine = nil
            Adhearsion.config.platform.media.default_renderer = nil
          end
        end

        describe "converts the argument to a string" do
          it 'calls output with a string' do
            argument = 123
            ssml = RubySpeech::SSML.draw { string '123' }
            expect_async_ssml_output ssml
            expect(subject.say!(argument)).to be_a Punchblock::Component::Output
          end
        end
      end

      describe "#speak!" do
        it "should be an alias for #say!" do
          expect(subject.method(:speak!)).to eq(subject.method(:say!))
        end
      end

      describe "#say_characters" do
        context "with a string" do
          let :ssml do
            RubySpeech::SSML.draw do
              say_as(interpret_as: 'characters') { "1234#abc" }
            end
          end

          it 'plays the correct ssml' do
            expect_ssml_output ssml
            expect(subject.say_characters('1234#abc')).to be true
          end
        end

        context "with a numeric" do
          let :ssml do
            RubySpeech::SSML.draw do
              say_as(interpret_as: 'characters') { "1234" }
            end
          end

          it 'plays the correct ssml' do
            expect_ssml_output ssml
            expect(subject.say_characters(1234)).to be true
          end
        end
      end

      describe "#say_characters!" do
        context "with a string" do
          let :ssml do
            RubySpeech::SSML.draw do
              say_as(interpret_as: 'characters') { "1234#abc" }
            end
          end

          it 'plays the correct ssml' do
            expect_async_ssml_output ssml
            expect(subject.say_characters!('1234#abc')).to be_a Punchblock::Component::Output
          end
        end

        context "with a numeric" do
          let :ssml do
            RubySpeech::SSML.draw do
              say_as(interpret_as: 'characters') { "1234" }
            end
          end

          it 'plays the correct ssml' do
            expect_async_ssml_output ssml
            expect(subject.say_characters!(1234)).to be_a Punchblock::Component::Output
          end
        end
      end
    end
  end
end
