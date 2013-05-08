#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Canvas::Builders::EnrollmentDateBuilder do

  describe "#build" do

    before do
      course_with_teacher(:active_all => true)
      @teacher_enrollment = @enrollment
      course_with_student(:active_all => true, :course => @course)
      @student_enrollment = @enrollment

      @section = @course.course_sections.first
      @term = @course.enrollment_term
    end

    def test_builder(enrollment, res)
      Canvas::Builders::EnrollmentDateBuilder.build(enrollment).map{|d|d.map(&:to_i)}.should == res.map{|d|d.map(&:to_i)}
    end

    context "has enrollment dates from enrollment" do
      append_before do
        @teacher_enrollment.start_at = 2.days.from_now
        @teacher_enrollment.end_at = 4.days.from_now
        @teacher_enrollment.save!
        @student_enrollment.start_at = 1.days.from_now
        @student_enrollment.end_at = 3.days.from_now
        @student_enrollment.save!
      end

      it "for teacher" do
        test_builder @teacher_enrollment, [[@teacher_enrollment.start_at, @teacher_enrollment.end_at]]
      end

      it "for student" do
        test_builder @student_enrollment, [[@student_enrollment.start_at, @student_enrollment.end_at]]
      end
    end

    context "has enrollment dates from section" do
      append_before do
        @section.restrict_enrollments_to_section_dates = true
        @section.start_at = 1.days.ago
        @section.end_at = 3.days.from_now
        @section.save!

        @term.start_at = 3.days.from_now
        @term.end_at = 5.days.from_now
        @term.save!
        @teacher_enrollment.reload
        @student_enrollment.reload
      end

      it "for teacher" do
        test_builder @teacher_enrollment, [[@section.start_at, @section.end_at], [@term.start_at, @term.end_at]]
      end

      it "for teacher with no term dates" do
        @term.start_at = nil
        @term.end_at = nil
        @term.save!
        test_builder @teacher_enrollment, [[@section.start_at, @section.end_at], [nil,nil]]
      end

      it "for student" do
        test_builder @student_enrollment, [[@section.start_at, @section.end_at]]
      end
    end

    context "has enrollment dates from course" do
      append_before do
        @course.restrict_enrollments_to_course_dates = true
        @course.start_at = 2.days.from_now
        @course.conclude_at = 3.days.from_now
        @course.save!

        @term.start_at = 2.days.from_now
        @term.end_at = 5.days.from_now
        @term.save!
        @teacher_enrollment.reload
        @student_enrollment.reload
      end

      it "for teacher" do
        test_builder @teacher_enrollment, [[@course.start_at, @course.end_at], [@term.start_at, @term.end_at]]
      end

      it "for teacher with no term dates" do
        @term.start_at = nil
        @term.end_at = nil
        @term.save!
        test_builder @teacher_enrollment, [[@course.start_at, @course.end_at], [nil,nil]]
      end

      it "for student" do
        test_builder @student_enrollment, [[@course.start_at, @course.end_at]]
      end
    end

    context "has enrollment dates from term" do
      append_before do
        @term.start_at = 2.days.from_now
        @term.end_at = 5.days.from_now
        @term.save!
        @teacher_enrollment.reload
        @student_enrollment.reload
      end

      it "for teacher" do
        test_builder @teacher_enrollment, [[@term.start_at, @term.end_at]]
      end

      it "for student" do
        test_builder @student_enrollment, [[@term.start_at, @term.end_at]]
      end
    end

  end
end